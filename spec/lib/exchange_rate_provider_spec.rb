RSpec.describe ExchangeRateProvider do
  # oficial docs: https://currencyapi.com/docs/latest#latest-currency-exchange-data
  let(:fixture_path) do
    File.expand_path('fixtures/requests/currencyapi/get_latest_currency.json', __dir__)
  end

  let(:raw_json)    { File.read(fixture_path) }
  let(:sample_data) { JSON.parse(raw_json)['data'] }

  let(:success_response) do
    instance_double('Net::HTTPResponse',
                    is_a?: true,
                    code: '200',
                    body: raw_json)
  end

  let(:http_client) { double('HTTPClient') }

  subject(:provider) do
    described_class.new(
      http_client: http_client,
      api_key: 'dummy-key'
    )
  end

  describe '#initialize' do
    context 'when no api_key passed and ENV unset' do
      around do |ex|
        orig = ENV.delete('CURRENCY_API_KEY')
        ex.run
        ENV['CURRENCY_API_KEY'] = orig
      end

      it 'raises if ENV missing' do
        expect do
          described_class.new(http_client: http_client)
        end.to raise_error(RuntimeError, 'CURRENCY_API_KEY must be set')
      end
    end

    context 'when api_key passed explicitly' do
      it 'uses the provided key and http_client' do
        inst = described_class.new(http_client: http_client, api_key: 'key123')
        expect(inst.send(:api_key)).to     eq('key123')
        expect(inst.send(:http_client)).to eq(http_client)
      end
    end
  end

  describe '#latest' do
    before { allow(http_client).to receive(:get_response).and_return(success_response) }

    it 'builds correct URI without optional params' do
      expect(http_client).to receive(:get_response) do |uri|
        params = URI.decode_www_form(uri.query).to_h
        expect(params['apikey']).to        eq('dummy-key')
        expect(params['base_currency']).to eq('USD')
        expect(params).not_to have_key('currencies')
        success_response
      end
      provider.latest
    end

    it 'parses all rates' do
      expected = sample_data.transform_values { |h| h['value'] }
      expect(provider.latest).to eq(expected)
    end

    it 'filters by targets (string)' do
      expect(provider.latest(targets: 'BRL')).to eq(
        'BRL' => sample_data['BRL']['value']
      )
    end

    it 'filters by targets (array)' do
      expect(provider.latest(targets: %w[EUR USD])).to eq(
        'EUR' => sample_data['EUR']['value'],
        'USD' => sample_data['USD']['value']
      )
    end

    it 'is case-insensitive for base & targets' do
      expect(provider.latest(base: 'eur', targets: %w[usd brl])).to include(
        'USD' => sample_data['USD']['value'],
        'BRL' => sample_data['BRL']['value']
      )
    end

    context 'when HTTP errors occur' do
      shared_examples 'http error' do |code, expected_message, body = nil|
        let(:resp) do
          instance_double('Net::HTTPResponse',
                          is_a?: false,
                          code: code.to_s,
                          message: 'Ignored',
                          body: body)
        end
        before { allow(http_client).to receive(:get_response).and_return(resp) }

        it "raises for HTTP #{code}" do
          expect { provider.latest }
            .to raise_error(RuntimeError, expected_message)
        end
      end

      it_behaves_like 'http error', 403,
                      'Forbidden: you are not allowed to use this endpoint, please upgrade your plan'
      it_behaves_like 'http error', 404,
                      'Endpoint not found'

      context '422 with JSON error body' do
        it_behaves_like 'http error',
                        422,
                        'Validation error (): Currency ABC is invalid',
                        {
                          'error' => {
                            'message' => 'Currency ABC is invalid'
                          }
                        }.to_json
      end

      it_behaves_like 'http error', 429,
                      'Rate limit exceeded, please upgrade your plan'
      it_behaves_like 'http error', 500,
                      'Server error 500: Ignored'
    end

    context 'when body is invalid JSON' do
      let(:bad) { instance_double('Net::HTTPResponse', is_a?: true, code: '200', body: 'nope') }
      before { allow(http_client).to receive(:get_response).and_return(bad) }

      it 'raises invalid JSON' do
        expect { provider.latest }.to raise_error(RuntimeError, 'Invalid JSON response')
      end
    end

    context 'when JSON has no data key' do
      let(:bad_json) { { 'foo' => {} }.to_json }
      let(:bad)      { instance_double('Net::HTTPResponse', is_a?: true, code: '200', body: bad_json) }
      before { allow(http_client).to receive(:get_response).and_return(bad) }

      it 'raises KeyError' do
        expect { provider.latest }.to raise_error(KeyError)
      end
    end

    context 'when network fails' do
      before { allow(http_client).to receive(:get_response).and_raise(SocketError.new('down')) }

      it 'raises network error' do
        expect { provider.latest }.to raise_error(RuntimeError, 'Network error: down')
      end
    end
  end
end

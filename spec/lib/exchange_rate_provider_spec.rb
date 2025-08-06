# frozen_string_literal: true

require_relative '../../lib/exchange_rate_provider'

RSpec.describe ExchangeRateProvider do
  let(:sample_data) do
    {
      'USD' => { 'code' => 'USD', 'value' => 1.0 },
      'BRL' => { 'code' => 'BRL', 'value' => 5.5 },
      'EUR' => { 'code' => 'EUR', 'value' => 0.9 }
    }
  end

  let(:json) do
    { 'meta' => {}, 'data' => sample_data }.to_json
  end

  let(:success_response) do
    instance_double('Net::HTTPResponse', is_a?: true, body: json)
  end

  let(:error_response) do
    instance_double('Net::HTTPResponse', is_a?: false, code: '502', message: 'Bad Gateway')
  end

  let(:http_client) { double('HTTPClient') }

  subject(:provider) { described_class.new(http_client: http_client, api_key: 'dummy-key') }

  describe '#latest' do
    before do
      allow(http_client).to receive(:get_response).and_return(success_response)
    end

    it 'parses all rates into a flat hash' do
      expect(provider.latest).to eq('USD' => 1.0, 'BRL' => 5.5, 'EUR' => 0.9)
    end

    it 'uses only requested targets' do
      expect(provider.latest(targets: 'BRL')).to eq('BRL' => 5.5)
    end

    it 'allows an Array of targets' do
      expect(provider.latest(targets: %w[EUR USD])).to eq('EUR' => 0.9, 'USD' => 1.0)
    end

    it 'accepts a different base currency' do
      expect(provider.latest(base: 'EUR')).to eq('USD' => 1.0, 'BRL' => 5.5, 'EUR' => 0.9)
    end

    context 'when HTTP returns non-success' do
      before do
        allow(http_client).to receive(:get_response).and_return(error_response)
      end

      it 'raises an HTTP error' do
        expect { provider.latest }
          .to raise_error(RuntimeError, /HTTP error 502: Bad Gateway/)
      end
    end

    context 'when body is invalid JSON' do
      let(:invalid_response) { instance_double('Net::HTTPResponse', is_a?: true, body: 'not a json') }

      before do
        allow(http_client).to receive(:get_response).and_return(invalid_response)
      end

      it 'raises an invalid JSON error' do
        expect { provider.latest }
          .to raise_error(RuntimeError, /Invalid JSON response/)
      end
    end

    context 'when JSON has no data key' do
      let(:bad_json)      { { 'foo' => {} }.to_json }
      let(:bad_response)  { instance_double('Net::HTTPResponse', is_a?: true, body: bad_json) }

      before do
        allow(http_client).to receive(:get_response).and_return(bad_response)
      end

      it 'raises a KeyError' do
        expect { provider.latest }
          .to raise_error(KeyError)
      end
    end
  end

  describe '#rate' do
    it 'fetches a single rate via #latest' do
      allow(provider).to receive(:latest)
        .with(base: 'USD', targets: 'BRL')
        .and_return('BRL' => 5.5)

      expect(provider.rate('USD', 'BRL')).to eq(5.5)
    end

    it 'raises if the code is missing' do
      allow(provider).to receive(:latest).and_return('EUR' => 0.9)

      expect { provider.rate('USD', 'BRL') }.to raise_error(KeyError)
    end
  end
end

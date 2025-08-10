require "rails_helper"

RSpec.describe ExchangeRateProvider do
  let(:fixture_path) do
    File.expand_path("fixtures/requests/currencyapi/get_latest_currency.json", __dir__)
  end

  let(:raw_json)    { File.read(fixture_path) }
  let(:sample_data) { JSON.parse(raw_json)["data"] }

  subject(:provider) { described_class.new(api_key: "dummy-key") }

  let(:http_resp) do
    ->(code:, body: "") { instance_double("HTTParty::Response", code: code, body: body) }
  end

  describe "#initialize" do
    it "raises if api_key is missing" do
      expect { described_class.new }.to raise_error(RuntimeError, "CURRENCY_API_KEY must be set")
    end

    it "accepts an explicit api_key" do
      inst = described_class.new(api_key: "key123")
      expect(inst).to be_a(ExchangeRateProvider)
    end
  end

  describe "#latest" do
    before do
      allow(described_class).to receive(:get).and_return(http_resp.call(code: 200, body: raw_json))
    end

    it "calls HTTParty.get with the correct path and base params" do
      expect(described_class).to receive(:get)
        .with("/v3/latest", query: hash_including(apikey: "dummy-key", base_currency: "USD"))
        .and_return(http_resp.call(code: 200, body: raw_json))

      provider.latest
    end

    it "does not include currencies when targets is nil" do
      expect(described_class).to receive(:get) do |path, opts|
        expect(path).to eq("/v3/latest")
        expect(opts[:query]).to include(apikey: "dummy-key", base_currency: "USD")
        expect(opts[:query]).not_to have_key(:currencies)
        http_resp.call(code: 200, body: raw_json)
      end
      provider.latest
    end

    it "adds currencies when targets is a string" do
      expect(described_class).to receive(:get) do |path, opts|
        expect(path).to eq("/v3/latest")
        expect(opts[:query][:currencies]).to eq("BRL")
        http_resp.call(code: 200, body: raw_json)
      end
      provider.latest(targets: "BRL")
    end

    it "adds currencies when targets is an array" do
      expect(described_class).to receive(:get) do |path, opts|
        expect(path).to eq("/v3/latest")
        expect(opts[:query][:currencies]).to eq("EUR,USD")
        http_resp.call(code: 200, body: raw_json)
      end
      provider.latest(targets: %w[EUR USD])
    end

    it "parses and returns all rates" do
      expected = sample_data.transform_values { |h| h["value"] }
      expect(provider.latest).to eq(expected)
    end

    it "is case-insensitive for base & targets and filters correctly" do
      allow(described_class).to receive(:get).and_return(http_resp.call(code: 200, body: raw_json))
      result = provider.latest(base: "eur", targets: %w[usd brl])
      expect(result).to include(
        "USD" => sample_data["USD"]["value"],
        "BRL" => sample_data["BRL"]["value"]
      )
    end

    context "HTTP errors" do
      shared_examples "http error" do |code, message, body = ""|
        it "raises for #{code}" do
          allow(described_class).to receive(:get).and_return(http_resp.call(code: code, body: body))
          expect { provider.latest }.to raise_error(RuntimeError, message)
        end
      end

      include_examples "http error", 403,
        "Forbidden: you are not allowed to use this endpoint, please upgrade your plan"

      include_examples "http error", 404, "Endpoint not found"

      include_examples "http error", 422,
        "Validation error (): Currency ABC is invalid",
        { "error" => { "message" => "Currency ABC is invalid" } }.to_json

      include_examples "http error", 429,
        "Rate limit exceeded, please upgrade your plan"

      it "falls back to generic message for unexpected codes" do
        allow(described_class).to receive(:get).and_return(http_resp.call(code: 418, body: ""))
        expect { provider.latest }.to raise_error(RuntimeError, "HTTP error 418")
      end

      it "500..599 returns server error without relying on #message" do
        allow(described_class).to receive(:get).and_return(http_resp.call(code: 500, body: ""))
        expect { provider.latest }.to raise_error(RuntimeError, "Server error 500")
      end
    end

    context "when response body is invalid JSON" do
      it "raises 'Invalid JSON response'" do
        allow(described_class).to receive(:get).and_return(http_resp.call(code: 200, body: "nope"))
        expect { provider.latest }.to raise_error(RuntimeError, "Invalid JSON response")
      end
    end

    context "when JSON has no data key" do
      it "raises KeyError" do
        bad = { "foo" => {} }.to_json
        allow(described_class).to receive(:get).and_return(http_resp.call(code: 200, body: bad))
        expect { provider.latest }.to raise_error(KeyError)
      end
    end

    context "when the network fails" do
      it "raises a network error" do
        allow(described_class).to receive(:get).and_raise(SocketError.new("down"))
        expect { provider.latest }.to raise_error(RuntimeError, "Network error: down")
      end
    end
  end
end

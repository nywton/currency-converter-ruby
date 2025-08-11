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

  let(:fake_logger) { double("Logger", info: nil, warn: nil, error: nil) }

  before do
    allow(provider).to receive(:sleep)
    allow(Rails).to receive(:logger).and_return(fake_logger)
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

    it "logs request and response with redacted apikey" do
      provider.latest

      expect(fake_logger).to have_received(:info).with(hash_including(
        event:   "currencyapi.request",
        verb:    "GET",
        path:    "/v3/latest",
        attempt: 1,
        query:   hash_including(apikey: "[REDACTED]", base_currency: "USD")
      ))

      expect(fake_logger).to have_received(:info).with(hash_including(
        event:       "currencyapi.response",
        path:        "/v3/latest",
        http_code:   200,
        duration_ms: kind_of(Integer)
      ))
    end

    context "retry logic" do
      it "retries on 500 and then succeeds, logging a retry" do
        allow(described_class).to receive(:get)
          .and_return(
            http_resp.call(code: 500, body: ""),
            http_resp.call(code: 200, body: raw_json)
          )

        expect(provider.latest).to be_a(Hash)
        expect(described_class).to have_received(:get).twice
        expect(fake_logger).to have_received(:warn).with(hash_including(
          event: "currencyapi.retry",
          attempt: 1,
          http_code: 500
        ))
      end

      it "retries on 429 and then succeeds, logging a retry" do
        allow(described_class).to receive(:get)
          .and_return(
            http_resp.call(code: 429, body: ""),
            http_resp.call(code: 200, body: raw_json)
          )

        expect(provider.latest).to be_a(Hash)
        expect(described_class).to have_received(:get).twice
        expect(fake_logger).to have_received(:warn).with(hash_including(
          event: "currencyapi.retry",
          attempt: 1,
          http_code: 429
        ))
      end

      it "retries on a network error and then succeeds, logging a retry" do
        calls = [
          -> { raise Net::ReadTimeout.new("rt") },
          -> { http_resp.call(code: 200, body: raw_json) }
        ]
        allow(described_class).to receive(:get) { calls.shift.call }

        expect(provider.latest).to be_a(Hash)
        expect(described_class).to have_received(:get).twice
        expect(fake_logger).to have_received(:warn).with(hash_including(
          event: "currencyapi.retry",
          attempt: 1,
          error: "Net::ReadTimeout"
        ))
      end

      it "gives up after MAX_RETRIES for 500 and raises server error" do
        attempts = described_class::MAX_RETRIES + 1
        allow(described_class).to receive(:get)
          .and_return(*Array.new(attempts) { http_resp.call(code: 500, body: "") })

        expect { provider.latest }.to raise_error(RuntimeError, "Server error 500")
        expect(described_class).to have_received(:get).exactly(attempts).times
      end

      it "gives up after MAX_RETRIES for 429 and raises rate limit" do
        attempts = described_class::MAX_RETRIES + 1
        allow(described_class).to receive(:get)
          .and_return(*Array.new(attempts) { http_resp.call(code: 429, body: "") })

        expect { provider.latest }.to raise_error(RuntimeError, "Rate limit exceeded")
        expect(described_class).to have_received(:get).exactly(attempts).times
      end

      it "gives up after MAX_RETRIES for network errors and raises Network error: ..." do
        allow(described_class).to receive(:get) { raise SocketError.new("down") }

        expect { provider.latest }.to raise_error(RuntimeError, "Network error: down")
        expect(described_class).to have_received(:get).exactly(described_class::MAX_RETRIES + 1).times
      end
    end

    context "HTTP errors" do
      shared_examples "http error" do |code, message, body = ""|
        it "raises for #{code}" do
          allow(described_class).to receive(:get).and_return(http_resp.call(code: code, body: body))
          expect { provider.latest }.to raise_error(RuntimeError, message)
        end
      end

      include_examples "http error", 403, "Forbidden: please upgrade your plan"
      include_examples "http error", 404, "Endpoint not found"
      include_examples "http error", 422,
        "Validation error (validation): Currency ABC is invalid",
        { "error" => { "type" => "validation", "message" => "Currency ABC is invalid" } }.to_json
      include_examples "http error", 429, "Rate limit exceeded"

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
      it "logs the parse error and raises 'Invalid JSON response'" do
        allow(described_class).to receive(:get).and_return(http_resp.call(code: 200, body: "nope"))

        expect { provider.latest }.to raise_error(RuntimeError, "Invalid JSON response")

        expect(fake_logger).to have_received(:error).with(hash_including(
          event:   "currencyapi.json_parse_error",
          error:   "JSON::ParserError",
          message: kind_of(String),
          snippet: kind_of(String)
        ))
      end
    end

    context "when JSON has no data key" do
      it "raises KeyError" do
        bad = { "foo" => {} }.to_json
        allow(described_class).to receive(:get).and_return(http_resp.call(code: 200, body: bad))
        expect { provider.latest }.to raise_error(KeyError)
      end
    end

    context "when the network fails once and never recovers (covered above too)" do
      it "raises a network error" do
        allow(described_class).to receive(:get) { raise SocketError.new("down") }
        expect { provider.latest }.to raise_error(RuntimeError, "Network error: down")
      end
    end
  end
end

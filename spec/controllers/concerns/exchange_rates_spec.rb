require "rails_helper"

RSpec.describe "ExchangeRates concern", type: :controller do
  controller(ActionController::Base) do
    include ExchangeRates

    def index
      render json: { rates: latest_usd_rates }
    end
  end

  let(:api_key)  { "test-currency-api-key" }
  let(:provider) { instance_double(ExchangeRateProvider, latest: { "USD" => 1.0, "BRL" => 5.0 }) }

  around do |example|
    original = Rails.configuration.x.currency_api_key
    Rails.configuration.x.currency_api_key = api_key
    example.run
  ensure
    Rails.configuration.x.currency_api_key = original
  end

  before do
    routes.draw { get "index" => "anonymous#index" }
  end

  describe "helper exposure" do
    it "exposes latest_usd_rates as a helper method" do
      expect(controller.view_context.respond_to?(:latest_usd_rates)).to be(true)
    end
  end

  describe "#exchange_rates_provider" do
    it "initializes ExchangeRateProvider with the configured API key" do
      expect(ExchangeRateProvider).to receive(:new).with(api_key: api_key).and_return(provider)
      controller.send(:exchange_rates_provider)
    end

    it "memoizes the provider" do
      allow(ExchangeRateProvider).to receive(:new).with(api_key: api_key).and_return(provider)

      first  = controller.send(:exchange_rates_provider)
      second = controller.send(:exchange_rates_provider)

      expect(first).to be(second)
      expect(ExchangeRateProvider).to have_received(:new).once
    end
  end

  describe "#latest_usd_rates" do
    include ActiveSupport::Testing::TimeHelpers

    it "reads from cache with key 'exchange_rates:all' and expires at end of day" do
      travel_to Time.zone.parse("2025-08-09 15:30:00") do
        expected_expires_in = (Time.current.end_of_day - Time.current).to_i

        allow(ExchangeRateProvider).to receive(:new).and_return(provider)

        expect(Rails.cache).to receive(:fetch)
          .with("exchange_rates:all", hash_including(expires_in: expected_expires_in))
          .and_wrap_original { |m, *args, &block| m.call(*args, &block) }

        get :index
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)["rates"]).to eq({ "USD" => 1.0, "BRL" => 5.0 })
      end
    end

    it "memoizes the result within the request and does not call provider twice" do
      allow(ExchangeRateProvider).to receive(:new).and_return(provider)
      allow(Rails.cache).to receive(:fetch).and_call_original

      get :index
      controller.send(:latest_usd_rates)

      expect(provider).to have_received(:latest).once
    end
  end

  describe "#seconds_to_midnight" do
    include ActiveSupport::Testing::TimeHelpers

    it "returns the number of whole seconds until end of day" do
      travel_to Time.zone.parse("2025-08-09 23:59:00") do
        expect(controller.send(:seconds_to_midnight)).to be_between(59, 60).inclusive
      end
    end
  end
end

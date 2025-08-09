module ExchangeRates
  extend ActiveSupport::Concern

  included do
    helper_method :latest_usd_rates if respond_to?(:helper_method)
  end

  private

  def latest_usd_rates
    @latest_exchange_rates ||= Rails.cache.fetch("exchange_rates:all", expires_in: seconds_to_midnight) do
      exchange_rates_provider.latest
    end
  end

  def exchange_rates_provider
    @exchange_rates_provider ||= ExchangeRateProvider.new(api_key: Rails.configuration.x.currency_api_key)
  end

  def seconds_to_midnight
    (Time.current.end_of_day - Time.current).to_i
  end
end

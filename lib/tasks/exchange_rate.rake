namespace :exchange_rates do
  desc "Fetch and cache the latest exchange rates"
  task latest: :environment do
    seconds_to_midnight = (Time.current.end_of_day - Time.current).to_i

    latest_rates = Rails.cache.fetch(
      "exchange_rates:all",
      expires_in: seconds_to_midnight
    ) do
      ExchangeRateProvider.new(api_key: ENV.fetch("CURRENCY_API_KEY")).latest
    end

    pp latest_rates
  end
end

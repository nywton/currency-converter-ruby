unless Rails.env.test?
  raise "Missing CURRENCY_API_KEY. Check README section Configuration" unless ENV.key?("CURRENCY_API_KEY")

  Rails.configuration.x.currency_api_key =
    Rails.application.credentials.currency_api_key || ENV.fetch("CURRENCY_API_KEY")
end

require "httparty"
require "json"

# ExchangeRateProvider fetches exchange rates from CurrencyAPI.
#
# @example
#   provider = ExchangeRateProvider.new(api_key: ENV.fetch("CURRENCY_API_KEY"))
#   rates    = provider.latest(base: "USD", targets: %w[EUR BRL])
#   puts rates # => { "EUR" => 0.92, "BRL" => 5.12 }
#
# @see https://currencyapi.com/docs/latest#latest-currency-exchange-data
class ExchangeRateProvider
  include HTTParty

  base_uri "https://api.currencyapi.com"

  def initialize(api_key: nil, version: "v3")
    @params  = {}
    @params[:apikey] = api_key || raise("CURRENCY_API_KEY must be set")
    @version = version
  end

  # Fetches the latest exchange rates from CurrencyAPI.
  #
  # @param base    [String] base currency code (default "USD")
  # @param targets [Array<String>, String, nil] target currency codes
  # @return [Hash<String, Float>]
  def latest(base: "USD", targets: nil)
    @params[:base_currency] = base.to_s.upcase
    @params[:currencies]    = Array(targets).map(&:upcase).join(",") if targets

    response = self.class.get("/#{@version}/latest", query: @params)
    handle_http_errors!(response)

    parsed = parse_json!(response.body)
    rates  = extract_rates(parsed)
    filter_rates(rates, targets)
  rescue SocketError => e
    raise "Network error: #{e.message}"
  end

  private

  def handle_http_errors!(resp)
    code = resp.code.to_i
    return if code.between?(200, 299)

    case code
    when 403 then raise "Forbidden: you are not allowed to use this endpoint, please upgrade your plan"
    when 404 then raise "Endpoint not found"
    when 422 then raise_validation_error!(resp.body)
    when 429 then raise "Rate limit exceeded, please upgrade your plan"
    when 500..599 then raise "Server error #{code}"
    else
      raise "HTTP error #{code}"
    end
  end

  def raise_validation_error!(body)
    error   = JSON.parse(body)
    type    = error.dig("error", "type")
    message = error.dig("error", "message")
    raise "Validation error (#{type}): #{message}"
  rescue JSON::ParserError
    raise "Validation error (422)"
  end

  def parse_json!(body)
    JSON.parse(body)
  rescue JSON::ParserError
    raise "Invalid JSON response"
  end

  def extract_rates(parsed_body)
    parsed_body.fetch("data")
               .transform_values { |h| h.fetch("value") }
  end

  def filter_rates(rates, targets)
    return rates unless targets
    allowed = Array(targets).map(&:upcase)
    rates.slice(*allowed)
  end
end

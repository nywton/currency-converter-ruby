# frozen_string_literal: true

require "net/http"
require "json"
require "uri"

# ExchangeRateProvider fetches exchange rates from CurrencyAPI.
#
# @example
#   ExchangeRateProvider.new(
#     http_client: Net::HTTP,
#     api_key: 'your‐api‐key'
#   ).latest
#   # ⇒ { "USD" => 1.0, "EUR" => 0.92, ... }
#
# @see https://currencyapi.com/docs/latest#latest-currency-exchange-data
class ExchangeRateProvider
  API_URL = "https://api.currencyapi.com/v3/latest"

  # @param http_client [#get_response] any object responding to get_response(uri)
  # @param api_key     [String]        your CurrencyAPI key (defaults to ENV)
  def initialize(http_client: Net::HTTP, api_key: nil)
    @api_key     = api_key || raise("CURRENCY_API_KEY must be set")
    @http_client = http_client
  end

  # Fetches the latest exchange rates.
  # oficial docs: https://currencyapi.com/docs/latest#latest-currency-exchange-data#
  #
  # @param base    [String]           The base currency (e.g. 'USD')
  # @param targets [Array<String>, String, nil] list of target codes to filter by (e.g. %w[EUR USD])
  # @return [Hash<String, Float>]
  def latest(base: "USD", targets: nil)
    uri      = build_uri(base, targets)
    response = fetch_response(uri)
    handle_http_errors!(response)

    parsed = parse_json!(response.body)
    rates  = extract_rates(parsed)

    filter_rates(rates, targets)
  rescue SocketError => e
    raise "Network error: #{e.message}"
  end

  private

  def build_uri(base, targets)
    uri    = URI(API_URL)
    params = {
      apikey: api_key,
      base_currency: base.to_s.upcase
    }
    params[:currencies] = Array(targets).map(&:upcase).join(",") if targets
    uri.query = URI.encode_www_form(params)
    uri
  end

  def fetch_response(uri)
    http_client.get_response(uri)
  end

  def handle_http_errors!(resp)
    return if resp.is_a?(Net::HTTPSuccess)

    case resp.code.to_i
    when 403 then raise "Forbidden: you are not allowed to use this endpoint, please upgrade your plan"
    when 404 then raise "Endpoint not found"
    when 422 then raise_validation_error!(resp.body)
    when 429 then raise "Rate limit exceeded, please upgrade your plan"
    when 500..599 then raise "Server error #{resp.code}: #{resp.message}"
    else
      raise "HTTP error #{resp.code}: #{resp.message}"
    end
  end

  def raise_validation_error!(body)
    error = JSON.parse(body)
    type = error.dig("error", "type")
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

  attr_reader :api_key, :http_client
end

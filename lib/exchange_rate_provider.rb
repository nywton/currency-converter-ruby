# frozen_string_literal: true

require 'net/http'
require 'json'
require 'uri'

class ExchangeRateProvider
  API_URL = 'https://api.currencyapi.com/v3/latest'

  # @param http_client [#get_response] any object that responds to get_response(uri)
  # @param api_key     [String]        your CurrencyAPI key
  def initialize(http_client: Net::HTTP, api_key: ENV.fetch('CURRENCY_API_KEY') do
    raise 'CURRENCY_API_KEY must be set'
  end)
    @http_client = http_client
    @api_key     = api_key
  end

  # @param base    [String]           The base currency (e.g. 'USD')
  # @param targets [Array<String>, String, nil]
  # @return [Hash<String, Float>]
  def latest(base: 'USD', targets: nil)
    uri = URI(API_URL)
    qs  = { apikey: @api_key, base_currency: base.upcase }
    qs[:currencies] = Array(targets).map(&:upcase).join(',') if targets
    uri.query = URI.encode_www_form(qs)

    resp = @http_client.get_response(uri)
    raise "HTTP error #{resp.code}: #{resp.message}" unless resp.is_a?(Net::HTTPSuccess)

    parsed = JSON.parse(resp.body)
    data   = parsed.fetch('data')
    rates  = data.transform_values { |h| h.fetch('value') }

    targets ? rates.select { |code, _| Array(targets).map(&:upcase).include?(code) } : rates
  rescue JSON::ParserError
    raise 'Invalid JSON response'
  rescue SocketError => e
    raise "Network error: #{e.message}"
  end

  # @param from [String]
  # @param to   [String]
  # @return [Float]
  def rate(from, to)
    latest(base: from, targets: to).fetch(to.upcase)
  end
end

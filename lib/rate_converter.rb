# frozen_string_literal: true

# RateConverter converts amounts between currencies using USD-based rates.
# It expects a hash mapping currency codes (strings) to their USD-relative rates (floats).
#
# Example usage:
#   provider = ExchangeRateProvider.new
#   rates    = provider.latest         # => { "USD"=>1.0, "BRL"=>5.5, ... }
#   conv     = RateConverter.new(rates)
#   conv.convert(100, base: 'BRL', target: 'EUR')
#   conv.convert_to_targets(100, base: 'USD', targets: ['JPY', 'GBP', 'AUD'])
class RateConverter
  # @param rates [Hash<String, Float>]
  #   e.g. { "USD" => 1.0, "EUR" => 0.8634, "BRL" => 5.5014 }
  def initialize(rates)
    @rates = rates.transform_keys(&:upcase)
  end

  # Convert amount from base currency to a single target currency.
  # @param amount [Numeric] the value in base currency (eg. 100)
  # @param base   [String]  currency code of amount to convert (eg. "USD")
  # @param target [String]  currency code to convert to (eg. "EUR", "JPY", "BRL")
  # @return [Hash] a hash with :rate and :to_value
  # @raise [ArgumentError] if base or target is not found in rates
  def convert(from_value, base:, target:)
    base_rate   = @rates.fetch(base.upcase)   { raise ArgumentError, "Unknown base currency: #{base}" }
    target_rate = @rates.fetch(target.upcase) { raise ArgumentError, "Unknown target currency: #{target}" }

    to_value = (from_value.to_f / base_rate) * target_rate

    { rate: target_rate, to_value: to_value }
  end

  private

  attr_reader :rates
end

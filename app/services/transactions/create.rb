module Transactions
  class Create
    attr_reader :errors, :transaction

    def initialize(user_id:, from_currency:, to_currency:, from_value:)
      @user_id       = user_id
      @from_currency = from_currency
      @to_currency   = to_currency
      @from_value    = from_value.to_d
      @errors        = []
    end

    def commit_with(usd_rates)
      begin
        converted = RateConverter.new(usd_rates).convert(
          @from_value,
          base:   @from_currency,
          target: @to_currency
        )
      rescue ArgumentError => e
        case e.message
        when /Unknown base currency/i
          errors << "From currency #{@from_currency} is not a supported currency code"
        when /Unknown target currency/i
          errors << "To currency #{@to_currency} is not a supported currency code"
        else
          errors << e.message
        end
        return self
      end

      @transaction = Transaction.new(
        user_id:       @user_id,
        from_currency: @from_currency,
        to_currency:   @to_currency,
        from_value:    @from_value,
        to_value:      converted[:to_value],
        rate:          converted[:rate]
      )

      errors.concat(transaction.errors.full_messages) unless transaction.save
      self
    end

    def success?
      errors.empty?
    end
  end
end

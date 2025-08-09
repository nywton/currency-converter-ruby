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
      converted = RateConverter.new(usd_rates).convert(@from_value, base: @from_currency, target: @to_currency)

      @transaction = Transaction.new(
        user_id:       @user_id,
        from_currency: @from_currency,
        to_currency:   @to_currency,
        from_value:    @from_value,
        to_value:      converted[:to_value],
        rate:          converted[:rate]
      )

      unless transaction.save
        errors.concat(transaction.errors.full_messages)
      end

      self
    end

    def success?
      errors.empty?
    end
  end
end

class TransactionsSerializer
  def initialize(record)
    @record = record
  end

  def as_json(*)
    {
      transaction_id: @record.id,
      user_id:        @record.user_id,
      from_currency:  @record.from_currency,
      to_currency:    @record.to_currency,
      from_value:     to_number(@record.from_value, 2),
      to_value:       to_number(@record.to_value, 2),
      rate:           to_number(@record.rate, 4),
      timestamp:      @record.created_at&.iso8601
    }
  end

  def self.collection(records)
    records.map { |r| new(r).as_json }
  end

  private

  def to_number(val, scale)
    return nil if val.nil?
    BigDecimal(val.to_s).round(scale).to_f
  end
end

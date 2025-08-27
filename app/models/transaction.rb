class Transaction < ApplicationRecord
  belongs_to :user

  validates :from_currency, :to_currency,
    presence: true,
    inclusion: {
      in:      Currencies::CODES,
      message: "%{value} is not a supported currency code"
    }

  validates :from_value, :to_value,
    numericality: {
      greater_than_or_equal_to: -9_999_999_999_999_999.99,
      less_than_or_equal_to:    9_999_999_999_999_999.99
    }

  validates :rate,
    numericality: {
      greater_than_or_equal_to: 0.0001,
      less_than_or_equal_to:    99_999_999_999_999.9999
    }

  alias_attribute :timestamp, :created_at

  def as_json(options = {})
    super(options).tap do |hash|
      hash["timestamp"] = created_at?.as_json
    end
  end
end

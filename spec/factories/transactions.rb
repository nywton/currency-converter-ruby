FactoryBot.define do
  factory :transaction do
    association :user

    from_currency { Currencies::CODES.sample }
    to_currency   { (Currencies::CODES - [ from_currency ]).sample }

    from_value { Faker::Number.decimal(l_digits: 6, r_digits: 2).to_f }
    to_value   { Faker::Number.decimal(l_digits: 6, r_digits: 2).to_f }
    rate       { (to_value / from_value).abs.round(4) }
  end
end

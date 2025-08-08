FactoryBot.define do
  factory :user do
    email_address { Faker::Internet.unique.email }
    password { "password" }
    password_confirmation { "password" }
  end
end

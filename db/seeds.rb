unless Rails.env.development?
  Rails.logger.info "Skipping seeds: not in development (env=#{Rails.env})."
  return
end

if User.exists?
  Rails.logger.info "Users already exist — skipping default user and transactions."
  return
end

ActiveRecord::Base.transaction do
  user = User.create!(
    email_address: 'user@example.com',
    password: 'supersecret'
  )

  Rails.logger.info "Created default user: #{user.id}"

  Transaction.create!([
    {
      user: user,
      from_currency: 'USD',
      to_currency: 'EUR',
      from_value: 100.00,
      to_value: 92.00,
      rate: 0.9200
    },
    {
      user: user,
      from_currency: 'EUR',
      to_currency: 'JPY',
      from_value: 50.00,
      to_value: 7700.00,
      rate: 154.0000
    },
    {
      user: user,
      from_currency: 'GBP',
      to_currency: 'USD',
      from_value: 75.00,
      to_value: 95.25,
      rate: 1.2700
    }
  ])

  Rails.logger.info "Added #{Transaction.count} transactions for #{user.id}"
end

unless Rails.env.test?
  raise "Missing JWT_SECRET. Check README section Configuration" unless ENV.key?("JWT_SECRET")

  Rails.configuration.x.jwt_secret =
    Rails.application.credentials.jwt_secret || ENV.fetch("JWT_SECRET")
end

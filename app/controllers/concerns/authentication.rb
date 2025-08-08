require "jwt"

module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :require_authentication
    helper_method :current_user if respond_to?(:helper_method)
  end

  private

  def current_user
    @current_user ||= fetch_user_from_token
  end

  def require_authentication
    return if current_user

    render_unauthorized
  end

  def fetch_user_from_token
    return unless (token = bearer_token)

    payload = decode_jwt(token)
    User.find_by(id: payload["user_id"])
  rescue JWT::DecodeError, ActiveRecord::RecordNotFound
    nil
  end

  def bearer_token
    header = request.headers["Authorization"]
    header&.match(/\ABearer (.+)\z/)&.captures&.first
  end

  def issue_jwt(user, exp: 24.hours.from_now.to_i)
    payload = { user_id: user.id, exp: exp }
    JWT.encode(payload, jwt_secret, "HS256")
  end

  def decode_jwt(token)
    JWT.decode(token, jwt_secret, true, algorithm: "HS256").first
  end

  def jwt_secret
    ENV.fetch("JWT_SECRET")
  end

  def render_unauthorized
    response.headers["WWW-Authenticate"] = 'Bearer realm="Application"'
    render json: { error: "Unauthorized" }, status: :unauthorized
  end
end

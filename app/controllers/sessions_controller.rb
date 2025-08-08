class SessionsController < ApplicationController
  skip_before_action :require_authentication

  def create
    return render_unauthorized unless (user = authenticate_user)

    render json: { token: issue_jwt(user) }, status: :created
  rescue ArgumentError
    render_unauthorized("Missing email or password")
  end

  private

  def authenticate_user
    User.authenticate_by(session_params)
  end

  def session_params
    params.permit(:email_address, :password)
  end

  def render_unauthorized(message = "Invalid credentials")
    render json: { error: message }, status: :unauthorized
  end
end

class CreateTransactionsController < ApplicationController
  include ExchangeRates

  rescue_from ActionController::ParameterMissing, with: :render_bad_request

  # POST /transactions
  def create
    service = build_service.commit_with(latest_usd_rates)
    if service.success?
      render json: TransactionsSerializer.new(service.transaction), status: :created
    else
      render json: { errors: service.errors }, status: :unprocessable_content
    end
  end

  private

  def build_service
    Transactions::Create.new(**permitted_params)
  end

  def permitted_params
    params
      .require(:transaction)
      .permit(:from_currency, :to_currency, :from_value)
      .to_h
      .symbolize_keys
      .merge(user_id: current_user.id)
  end

  def render_bad_request(exception)
    render json: { error: exception.message }, status: :bad_request
  end
end

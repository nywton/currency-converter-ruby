module Api
  module V1
    class TransactionsController < ApplicationController
      include ExchangeRates

      rescue_from ActionController::ParameterMissing, with: :render_bad_request

      # POST /api/v1/transactions
      def create
        service = build_service.commit_with(latest_usd_rates)
        render_service(service)
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

      def render_service(service)
        if service.success?
          render json: Api::V1::TransactionsSerializer.new(service.transaction), status: :created
        else
          render json: { errors: service.errors }, status: :unprocessable_content
        end
      end

      def render_bad_request(exception)
        render json: { error: exception.message }, status: :bad_request
      end
    end
  end
end

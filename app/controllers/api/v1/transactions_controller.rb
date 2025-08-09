module Api
  module V1
    class TransactionsController < ApplicationController
      include ExchangeRates

      # POST api/v1/transactions
      def create
        service = Transactions::Create.new(
          **transaction_params.symbolize_keys
        ).commit_with(latest_usd_rates)

        if service.success?
          render json: service.transaction, status: :created
        else
          render json: { errors: service.errors }, status: :unprocessable_content
        end
      end

      private

      def transaction_params
        params.require(:transaction).permit(
          :from_currency,
          :to_currency,
          :from_value,
        ).merge(user_id: current_user.id).to_h
      end
    end
  end
end

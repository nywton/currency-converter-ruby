class ListTransactionsController < ApplicationController
  before_action :require_authentication

  # GET /transactions?user_id=<user_id>
  def index
    user = target_user
    return render json: { error: "User not found" }, status: :not_found unless user

    transactions = Transaction.where(user_id: user.id).order(created_at: :desc)
    render json: TransactionsSerializer.collection(transactions)
  end

  private

  def target_user
    return current_user if permitted_params[:user_id].blank?
    User.find_by(id: permitted_params[:user_id])
  end

  def permitted_params
    params.permit(:user_id)
  end
end

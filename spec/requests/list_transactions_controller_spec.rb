require "rails_helper"

RSpec.describe ListTransactionsController, type: :request do
  let!(:current_user) { create(:user) }
  let(:headers)       { auth_headers_for(current_user) }
  let(:url)           { list_transactions_path }

  let!(:others_user)  { create(:user) }

  let!(:t_old_current) { create(:transaction, user: current_user, created_at: 2.days.ago) }
  let!(:t_new_current) { create(:transaction, user: current_user, created_at: 1.hour.ago) }

  let!(:t_old_other)   { create(:transaction, user: others_user, created_at: 3.days.ago) }
  let!(:t_new_other)   { create(:transaction, user: others_user, created_at: 30.minutes.ago) }

  describe "GET /transactions" do
    context "when user_id is omitted" do
      it "returns the current_user transactions ordered by newest first" do
        get url, headers: headers

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)

        expect(json).to be_an(Array)
        expect(json.map { |h| h["transaction_id"] }).to eq([ t_new_current.id, t_old_current.id ])
        expect(json).not_to include(hash_including("transaction_id" => t_new_other.id))
      end
    end

    context "when user_id points to an existing user" do
      it "returns that user's transactions ordered by newest first" do
        get url, params: { user_id: others_user.id }, headers: headers

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)

        expect(json.map { |h| h["transaction_id"] }).to eq([ t_new_other.id, t_old_other.id ])
      end
    end

    context "when user_id does not exist" do
      it "returns 404 with an error message" do
        get url, params: { user_id: 999_999 }, headers: headers

        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body)
        expect(json).to eq("error" => "User not found")
      end
    end
  end
end

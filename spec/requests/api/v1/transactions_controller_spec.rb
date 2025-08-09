require 'rails_helper'

RSpec.describe Api::V1::TransactionsController, type: :request do
  let!(:user)   { create(:user) }
  let(:headers) { auth_headers_for(user) }
  let(:url)     { api_v1_transactions_path }

  let(:valid_attributes) do
    {
      transaction: {
        from_currency: "USD",
        to_currency:   "BRL",
        from_value:    100.0
      }
    }
  end

  let(:invalid_attributes) do
    {
      transaction: {
        from_currency: "XXX",
        to_currency:   "BRL",
        from_value:    100.0
      }
    }
  end

  let(:rates) do
    {
      'USD' => 1.0,
      'EUR' => 0.8,
      'BRL' => 5.0,
      'JPY' => 147.0
    }
  end

  before { allow_any_instance_of(ExchangeRateProvider).to receive(:latest).and_return(rates) }

  describe "POST /api/v1/transactions" do
    context "with valid params" do
      subject(:create_with_valid_params) do
        post url, params: valid_attributes.to_json, headers: headers
        response
      end

      subject(:json) { JSON.parse(create_with_valid_params.body) }

      it { expect { create_with_valid_params }.to change(Transaction, :count).by(1) }

      it { expect(create_with_valid_params).to have_http_status(201) }

      it { expect(json).to include(
        "transaction_id"         => Transaction.last.id,
        "from_value" => 100.0,
        "to_value"   => 500.0,
        "from_currency" => "USD",
        "to_currency"   => "BRL",
        "rate"       => 5.0,
        "timestamp"  => Transaction.last.created_at.iso8601
      ) }
    end

    context "with invalid params" do
      it "does not create a Transaction and returns 422 with error messages" do
        expect {
          post url, params: invalid_attributes.to_json, headers: headers
        }.not_to change(Transaction, :count)

        expect(response).to have_http_status(:unprocessable_content)
        json = JSON.parse(response.body)
        expect(json["errors"]).to include(
          "From currency XXX is not a supported currency code"
        )
      end
    end

    context "without Authorization header" do
      it "returns 401 Unauthorized" do
        post url, params: valid_attributes.to_json, headers: { "Content-Type" => "application/json" }

        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)).to include("error" => "Unauthorized")
      end
    end
  end
end

require "rails_helper"
require "jwt"

RSpec.describe SessionsController, type: :request do
  let(:jwt_secret) { "test_secret" }
  let!(:user)       { create(:user, email_address: "jane@example.com", password: "secret", password_confirmation: "secret") }
  let(:url)        { session_path }
  let(:valid_attributes) { { email_address: "jane@example.com", password: "secret" } }

  describe "POST /session" do
    context "with valid credentials" do
      it "returns HTTP 201 and a valid JWT token" do
        post url, params: valid_attributes, as: :json

        expect(response).to have_http_status(:created)

        body = JSON.parse(response.body)
        expect(body).to have_key("token")
        expect(body.fetch("user_id")).to eq(user.id)

        token   = body.fetch("token")
        payload, = JWT.decode(token, jwt_secret, true, algorithm: "HS256")

        expect(payload["user_id"]).to eq(user.id)
        expect(payload).to have_key("exp")
      end
    end

    context "with invalid credentials" do
      before do
        allow(User).to receive(:authenticate_by).and_return(nil)
      end

      it "returns HTTP 401 and an Invalid credentials error" do
        post url,
             params: { email_address: "foo@bar.com", password: "wrong" },
             as: :json

        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)).to eq("error" => "Invalid credentials")
      end
    end

    context "when email_address is missing" do
      before do
        allow(User).to receive(:authenticate_by).and_raise(ArgumentError)
      end

      it "returns HTTP 401 and an Invalid credentials error" do
        post url,
             params: { password: "whatever" },
             as: :json

        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)).to eq("error" => "Missing email or password")
      end
    end

    context "when password is missing" do
      before do
        allow(User).to receive(:authenticate_by).and_raise(ArgumentError)
      end

      it "returns HTTP 401 and an Invalid credentials error" do
        post url,
             params: { email_address: "jane@example.com" },
             as: :json

        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)).to eq("error" => "Missing email or password")
      end
    end
  end
end

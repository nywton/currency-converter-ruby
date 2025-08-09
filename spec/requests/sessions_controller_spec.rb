require "rails_helper"
require "jwt"

RSpec.describe SessionsController, type: :request do
  let(:jwt_secret) { "test_secret" }
  let(:user)       { instance_double(User, id: 42) }
  let(:url)        { session_path }

  before do
    allow(ENV).to receive(:fetch).with("JWT_SECRET").and_return(jwt_secret)
  end

  describe "POST api/v1/session" do
    context "with valid credentials" do
      before do
        allow(User).to receive(:authenticate_by).and_return(user)
      end

      it "returns HTTP 201 and a valid JWT token" do
        post url,
             params: { email_address: "jane@example.com", password: "secret" },
             as: :json

        expect(response).to have_http_status(:created)

        body = JSON.parse(response.body)
        expect(body).to have_key("token")

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
        # simulate missing-param exception in authenticate_by
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

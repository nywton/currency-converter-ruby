require "rails_helper"

RSpec.describe Authentication, type: :controller do
  controller(ApplicationController) do
    include Authentication
    def index
      render json: { message: "success" }
    end
  end

  let(:secret_key) { "test_secret" }
  let(:user) { instance_double("User", id: 123) }

  before do
    allow(ENV).to receive(:fetch).with("JWT_SECRET").and_return(secret_key)
  end

  describe "before_action :require_authentication" do
    context "when no Authorization header" do
      it "responds with 401 Unauthorized" do
        get :index, format: :json

        expect(response).to have_http_status(:unauthorized)
        expect(response.headers["WWW-Authenticate"]).to eq('Bearer realm="Application"')
        expect(JSON.parse(response.body)).to eq("error" => "Unauthorized")
      end
    end

    context "with malformed token" do
      before { request.headers["Authorization"] = "Bearer invalid.token" }

      it "rescues decode errors and responds 401" do
        get :index, format: :json

        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)).to eq("error" => "Unauthorized")
      end
    end

    context "with valid token but user not found" do
      let(:token) { controller.send(:issue_jwt, user, exp: 1.hour.from_now.to_i) }

      before do
        allow(User).to receive(:find_by).with(id: user.id).and_return(nil)
        request.headers["Authorization"] = "Bearer #{token}"
      end

      it "responds 401 Unauthorized" do
        get :index, format: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "with valid token and existing user" do
      let(:token) { controller.send(:issue_jwt, user) }

      before do
        allow(User).to receive(:find_by).with(id: user.id).and_return(user)
        request.headers["Authorization"] = "Bearer #{token}"
      end

      it "allows access and sets current_user" do
        get :index, format: :json

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to eq("message" => "success")
        expect(controller.send(:current_user)).to eq(user)
      end
    end
  end

  describe "#bearer_token" do
    it "extracts token from valid header" do
      request.headers["Authorization"] = "Bearer abc.def.ghi"
      expect(controller.send(:bearer_token)).to eq("abc.def.ghi")
    end

    it "returns nil for missing or malformed header" do
      request.headers["Authorization"] = "Token abc.def"
      expect(controller.send(:bearer_token)).to be_nil

      request.headers["Authorization"] = nil
      expect(controller.send(:bearer_token)).to be_nil
    end
  end

  describe "#issue_jwt and #decode_jwt" do
    it "encodes and decodes payload correctly" do
      token = controller.send(:issue_jwt, user, exp: 2.hours.from_now.to_i)
      payload = controller.send(:decode_jwt, token)

      expect(payload["user_id"]).to eq(user.id)
      expect(payload).to have_key("exp")
    end
  end

  describe "#jwt_secret" do
    it "returns the SECRET_KEY_BASE from ENV" do
      expect(controller.send(:jwt_secret)).to eq(secret_key)
    end

    it "raises if env key missing" do
      allow(ENV).to receive(:fetch).and_raise(KeyError)
      expect { controller.send(:jwt_secret) }.to raise_error(KeyError)
    end
  end

  describe "#fetch_user_from_token" do
    it "returns nil without bearer token" do
      allow(controller).to receive(:bearer_token).and_return(nil)
      expect(controller.send(:fetch_user_from_token)).to be_nil
    end

    it "returns nil on decode errors" do
      allow(controller).to receive(:bearer_token).and_return("bad.token")
      expect(controller.send(:fetch_user_from_token)).to be_nil
    end

    it "returns user when token valid" do
      token = controller.send(:issue_jwt, user)
      allow(User).to receive(:find_by).with(id: user.id).and_return(user)
      request.headers["Authorization"] = "Bearer #{token}"

      expect(controller.send(:fetch_user_from_token)).to eq(user)
    end
  end
end

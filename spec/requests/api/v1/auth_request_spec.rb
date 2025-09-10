require "rails_helper"

RSpec.describe "API::V1::Auth", type: :request do
  describe "POST /api/v1/auth" do
    context "有効なパラメータの場合" do
      let(:valid_params) do
        {
          email: "test@example.com",
          password: "password123",
          password_confirmation: "password123",
          name: "テストユーザー"
        }
      end

      it "新規ユーザーが作成される" do
        expect {
          post "/api/v1/auth", params: valid_params
        }.to change(User, :count).by(1)
      end

      it "成功レスポンスが返される" do
        post "/api/v1/auth", params: valid_params

        expect(response).to have_http_status(:ok)
        expect(json_response["status"]).to eq("success")
      end

      it "ユーザー情報が正しく返される" do
        post "/api/v1/auth", params: valid_params

        data = json_response["data"]
        expect(data["email"]).to eq("test@example.com")
        expect(data["name"]).to eq("テストユーザー")
        expect(data["provider"]).to eq("email")
        expect(data["uid"]).to eq("test@example.com")
      end

      it "認証トークンがヘッダーに含まれる" do
        post "/api/v1/auth", params: valid_params

        expect(response.headers["access-token"]).to be_present
        expect(response.headers["client"]).to be_present
        expect(response.headers["uid"]).to eq("test@example.com")
      end
    end

    context "無効なパラメータの場合" do
      context "emailが重複している場合" do
        before do
          create(:user, email: "test@example.com")
        end

        it "エラーレスポンスが返される" do
          post "/api/v1/auth", params: {
            email: "test@example.com",
            password: "password123",
            password_confirmation: "password123",
            name: "テストユーザー"
          }

          expect(response).to have_http_status(:unprocessable_entity)
          expect(json_response["status"]).to eq("error")
        end
      end

      context "nameが空の場合" do
        it "エラーレスポンスが返される" do
          post "/api/v1/auth", params: {
            email: "test@example.com",
            password: "password123",
            password_confirmation: "password123",
            name: ""
          }

          expect(response).to have_http_status(:unprocessable_entity)
          expect(json_response["errors"]["name"]).to include("can't be blank")
        end
      end

      context "パスワードが一致しない場合" do
        it "エラーレスポンスが返される" do
          post "/api/v1/auth", params: {
            email: "test@example.com",
            password: "password123",
            password_confirmation: "different_password",
            name: "テストユーザー"
          }

          expect(response).to have_http_status(:unprocessable_entity)
          expect(json_response["status"]).to eq("error")
        end
      end
    end
  end
end

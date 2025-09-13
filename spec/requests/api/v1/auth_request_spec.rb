require "rails_helper"

RSpec.describe "API::V1::Auth", type: :request do
  describe "POST /api/v1/auth" do
    context "有効なパラメータの場合" do
      let(:valid_params) do
        {
          email: "test@example.com",
          password: "password123",
          password_confirmation: "password123",
          name: "テストユーザー",
        }
      end

      it "新規ユーザーが作成される" do
        expect {
          post "/api/v1/auth", params: valid_params
        }.to change { User.count }.by(1)
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
            name: "テストユーザー",
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
            name: "",
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
            name: "テストユーザー",
          }

          expect(response).to have_http_status(:unprocessable_entity)
          expect(json_response["status"]).to eq("error")
        end
      end
    end
  end

  describe "POST /api/v1/auth/sign_in" do
    let!(:user) { create(:user, email: "test@example.com", password: "password123", name: "テストユーザー") }

    context "有効な認証情報の場合" do
      let(:valid_login_params) do
        {
          email: "test@example.com",
          password: "password123",
        }
      end

      it "ログインが成功する" do
        post "/api/v1/auth/sign_in", params: valid_login_params

        expect(response).to have_http_status(:ok)
        expect(json_response["data"]["email"]).to eq("test@example.com")
        expect(json_response["data"]["name"]).to eq("テストユーザー")
      end

      it "認証トークンがヘッダーに含まれる" do
        post "/api/v1/auth/sign_in", params: valid_login_params

        expect(response.headers["access-token"]).to be_present
        expect(response.headers["client"]).to be_present
        expect(response.headers["uid"]).to eq("test@example.com")
      end

      it "ユーザー情報が正しく返される" do
        post "/api/v1/auth/sign_in", params: valid_login_params

        data = json_response["data"]
        expect(data["email"]).to eq("test@example.com")
        expect(data["name"]).to eq("テストユーザー")
        expect(data["provider"]).to eq("email")
        expect(data["uid"]).to eq("test@example.com")
      end
    end

    context "無効な認証情報の場合" do
      context "間違ったemailの場合" do
        it "ログインが失敗する" do
          post "/api/v1/auth/sign_in", params: {
            email: "wrong@example.com",
            password: "password123",
          }

          expect(response).to have_http_status(:unauthorized)
          expect(json_response["success"]).to eq(false)
          expect(json_response["errors"]).to include("Invalid login credentials. Please try again.")
        end
      end

      context "間違ったpasswordの場合" do
        it "ログインが失敗する" do
          post "/api/v1/auth/sign_in", params: {
            email: "test@example.com",
            password: "wrong_password",
          }

          expect(response).to have_http_status(:unauthorized)
          expect(json_response["success"]).to eq(false)
          expect(json_response["errors"]).to include("Invalid login credentials. Please try again.")
        end
      end

      context "emailが空の場合" do
        it "ログインが失敗する" do
          post "/api/v1/auth/sign_in", params: {
            email: "",
            password: "password123",
          }

          expect(response).to have_http_status(:unauthorized)
          expect(json_response["success"]).to eq(false)
        end
      end

      context "passwordが空の場合" do
        it "ログインが失敗する" do
          post "/api/v1/auth/sign_in", params: {
            email: "test@example.com",
            password: "",
          }

          expect(response).to have_http_status(:unauthorized)
          expect(json_response["success"]).to eq(false)
        end
      end
    end
  end

  describe "DELETE /api/v1/auth/sign_out" do
    let!(:user) { create(:user, email: "test@example.com", password: "password123") }

    context "有効な認証トークンでログアウト" do
      it "ログアウトが成功する" do
        # create_new_auth_tokenでトークンを生成
        auth_headers = user.create_new_auth_token

        # ログアウト
        delete "/api/v1/auth/sign_out", headers: auth_headers

        expect(response).to have_http_status(:ok)
        expect(json_response["success"]).to eq(true)
      end

      it "ログアウト後にトークンが無効になる" do
        # create_new_auth_tokenでトークンを生成
        auth_headers = user.create_new_auth_token

        # ログアウト
        delete "/api/v1/auth/sign_out", headers: auth_headers
        expect(response).to have_http_status(:ok)

        # ログアウト後のトークンでAPIアクセス
        get "/api/v1/auth/validate_token", headers: auth_headers
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "無効な認証トークンでログアウト" do
      it "ログアウトが失敗する" do
        delete "/api/v1/auth/sign_out", headers: {
          "access-token" => "invalid_token",
          "client" => "invalid_client",
          "uid" => "test@example.com",
        }

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "認証ヘッダーなしでログアウト" do
      it "ログアウトが失敗する" do
        delete "/api/v1/auth/sign_out"

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "GET /api/v1/auth/validate_token" do
    let!(:user) { create(:user, email: "test@example.com", password: "password123") }

    context "有効な認証トークンで検証" do
      it "トークンが有効であることが確認できる" do
        # まずログインしてトークンを取得
        post "/api/v1/auth/sign_in", params: {
          email: "test@example.com",
          password: "password123",
        }

        access_token = response.headers["access-token"]
        client = response.headers["client"]
        uid = response.headers["uid"]

        # トークン検証
        get "/api/v1/auth/validate_token", headers: {
          "access-token" => access_token,
          "client" => client,
          "uid" => uid,
        }

        expect(response).to have_http_status(:ok)
        expect(json_response["data"]["email"]).to eq("test@example.com")
      end
    end

    context "無効な認証トークンで検証" do
      it "トークンが無効であることが確認できる" do
        get "/api/v1/auth/validate_token", headers: {
          "access-token" => "invalid_token",
          "client" => "invalid_client",
          "uid" => "test@example.com",
        }

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end

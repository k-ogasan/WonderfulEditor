require "rails_helper"

RSpec.describe "Api::V1::Current::Articles", type: :request do
  let(:test_user) { create(:user, name: "テストユーザー", email: "test@example.com") }

  describe "GET /api/v1/current/articles" do
    context "認証済みユーザーの場合" do
      it "自分の公開記事一覧を取得できる" do
        auth_headers = test_user.create_new_auth_token
        create(:article, user: test_user, status: :published, title: "公開記事1")
        create(:article, user: test_user, status: :published, title: "公開記事2")
        create(:article, user: test_user, status: :draft, title: "下書き記事")

        get "/api/v1/current/articles", headers: auth_headers

        expect(response).to have_http_status(:ok)
        expect(json_response).to be_an(Array)
        expect(json_response.length).to eq(2)
        expect(json_response.map {|article| article["title"] }).to contain_exactly("公開記事1", "公開記事2")
        expect(json_response.all? {|article| article["status"] == "published" }).to be true
      end

      it "他のユーザーの公開記事は表示されない" do
        auth_headers = test_user.create_new_auth_token
        other_user = create(:user)
        create(:article, user: other_user, status: :published, title: "他人の公開記事")
        create(:article, user: test_user, status: :published, title: "自分の公開記事")

        get "/api/v1/current/articles", headers: auth_headers

        expect(response).to have_http_status(:ok)
        expect(json_response.length).to eq(1)
        expect(json_response.first["title"]).to eq("自分の公開記事")
      end

      it "下書き記事は表示されない" do
        auth_headers = test_user.create_new_auth_token
        create(:article, user: test_user, status: :draft, title: "下書き記事")

        get "/api/v1/current/articles", headers: auth_headers

        expect(response).to have_http_status(:ok)
        expect(json_response).to be_empty
      end

      it "公開記事がない場合は空の配列が返される" do
        auth_headers = test_user.create_new_auth_token

        get "/api/v1/current/articles", headers: auth_headers

        expect(response).to have_http_status(:ok)
        expect(json_response).to be_empty
      end
    end

    context "認証なしの場合" do
      it "401エラーが返される" do
        get "/api/v1/current/articles"

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end


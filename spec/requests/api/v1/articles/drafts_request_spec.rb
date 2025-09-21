require "rails_helper"

RSpec.describe "Api::V1::Articles::Drafts", type: :request do
  let(:test_user) { create(:user, name: "テストユーザー", email: "test@example.com") }

  describe "GET /api/v1/articles/drafts" do
    context "認証済みユーザーの場合" do
      it "自分の下書き記事一覧を取得できる" do
        auth_headers = test_user.create_new_auth_token
        create(:article, user: test_user, status: :draft, title: "下書き記事1")
        create(:article, user: test_user, status: :draft, title: "下書き記事2")
        create(:article, user: test_user, status: :published, title: "公開記事")

        get "/api/v1/articles/drafts", headers: auth_headers

        expect(response).to have_http_status(:ok)
        expect(json_response).to be_an(Array)
        expect(json_response.length).to eq(2)
        expect(json_response.map {|article| article["title"] }).to contain_exactly("下書き記事1", "下書き記事2")
        expect(json_response.all? {|article| article["status"] == "draft" }).to be true
      end

      it "他のユーザーの下書き記事は表示されない" do
        auth_headers = test_user.create_new_auth_token
        other_user = create(:user)
        create(:article, user: other_user, status: :draft, title: "他人の下書き記事")
        create(:article, user: test_user, status: :draft, title: "自分の下書き記事")

        get "/api/v1/articles/drafts", headers: auth_headers

        expect(response).to have_http_status(:ok)
        expect(json_response.length).to eq(1)
        expect(json_response.first["title"]).to eq("自分の下書き記事")
      end

      it "下書き記事がない場合は空の配列が返される" do
        auth_headers = test_user.create_new_auth_token

        get "/api/v1/articles/drafts", headers: auth_headers

        expect(response).to have_http_status(:ok)
        expect(json_response).to be_empty
      end
    end

    context "認証なしの場合" do
      it "401エラーが返される" do
        get "/api/v1/articles/drafts"

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "GET /api/v1/articles/drafts/:id" do
    let(:draft_article) { create(:article, user: test_user, status: :draft, title: "下書き記事") }

    context "認証済みユーザーの場合" do
      it "自分の下書き記事詳細を取得できる" do
        auth_headers = test_user.create_new_auth_token

        get "/api/v1/articles/drafts/#{draft_article.id}", headers: auth_headers

        expect(response).to have_http_status(:ok)
        expect(json_response["id"]).to eq(draft_article.id)
        expect(json_response["title"]).to eq(draft_article.title)
        expect(json_response["body"]).to eq(draft_article.body)
        expect(json_response["status"]).to eq("draft")
      end

      it "他のユーザーの下書き記事は取得できない" do
        auth_headers = test_user.create_new_auth_token
        other_user = create(:user)
        other_draft = create(:article, user: other_user, status: :draft, title: "他人の下書き記事")

        get "/api/v1/articles/drafts/#{other_draft.id}", headers: auth_headers

        expect(response).to have_http_status(:not_found)
        expect(json_response["error"]).to eq("下書き記事が見つかりません")
      end

      it "存在しない下書き記事の場合は404エラーが返される" do
        auth_headers = test_user.create_new_auth_token

        get "/api/v1/articles/drafts/99999", headers: auth_headers

        expect(response).to have_http_status(:not_found)
        expect(json_response["error"]).to eq("下書き記事が見つかりません")
      end

      it "公開記事の場合は404エラーが返される" do
        auth_headers = test_user.create_new_auth_token
        published_article = create(:article, user: test_user, status: :published, title: "公開記事")

        get "/api/v1/articles/drafts/#{published_article.id}", headers: auth_headers

        expect(response).to have_http_status(:not_found)
        expect(json_response["error"]).to eq("下書き記事が見つかりません")
      end
    end

    context "認証なしの場合" do
      it "401エラーが返される" do
        get "/api/v1/articles/drafts/#{draft_article.id}"

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end

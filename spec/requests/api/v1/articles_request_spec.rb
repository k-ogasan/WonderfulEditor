require "rails_helper"

RSpec.describe "Api::V1::Articles", type: :request do
  describe "GET /index" do
    it "記事一覧を取得できる" do
      # テストデータを作成
      article = create(:article)

      # APIリクエストを送信
      get "/api/v1/articles"

      # レスポンスを確認
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_an(Array)
      expect(json_response.first["title"]).to eq(article.title)
      expect(json_response.first["updated_at"]).to be_present
    end
  end

  describe "GET /show" do
    it "returns http success" do
      get "/api/v1/articles/show"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /create" do
    it "returns http success" do
      get "/api/v1/articles/create"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /update" do
    it "returns http success" do
      get "/api/v1/articles/update"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /destroy" do
    it "returns http success" do
      get "/api/v1/articles/destroy"
      expect(response).to have_http_status(:success)
    end
  end
end

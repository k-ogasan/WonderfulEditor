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

  describe "GET /api/v1/articles/:id" do
    let(:user) { create(:user) }
    let(:article) { create(:article, user: user) }

    context "記事が存在する場合" do
      it "認証なしで記事詳細を取得できる" do
        get "/api/v1/articles/#{article.id}"

        expect(response).to have_http_status(:ok)
        expect(json_response["id"]).to eq(article.id)
        expect(json_response["title"]).to eq(article.title)
        expect(json_response["body"]).to eq(article.body)
        expect(json_response["updated_at"]).to be_present
      end

      it "記事詳細に必要な属性が含まれている" do
        get "/api/v1/articles/#{article.id}"

        expect(json_response).to include(
          "id", "title", "body", "updated_at", "user"
        )
      end

      it "ユーザー情報が正しく含まれている" do
        get "/api/v1/articles/#{article.id}"

        expect(json_response["user"]["id"]).to eq(user.id)
        expect(json_response["user"]["name"]).to eq(user.name)
        expect(json_response["user"]["email"]).to eq(user.email)
      end

      it "更新日が正しく設定されている" do
        # 記事を作成してから更新
        original_updated_at = article.updated_at

        # 少し時間を経過させてから更新
        travel 1.hour do
          article.update!(title: "更新されたタイトル")
        end

        get "/api/v1/articles/#{article.id}"

        expect(json_response["updated_at"]).to eq(article.updated_at.as_json)
        expect(json_response["updated_at"]).not_to eq(original_updated_at.as_json)
      end

      it "ArticleDetailSerializerが正しく使用されている" do
        get "/api/v1/articles/#{article.id}"

        # プレビュー用シリアライザーには含まれないbodyが含まれていることを確認
        expect(json_response["body"]).to be_present
        # 必要最小限の属性のみが含まれていることを確認
        expect(json_response).not_to have_key("created_at")
        expect(json_response).not_to have_key("comments_count")
        expect(json_response).not_to have_key("likes_count")
        expect(json_response).not_to have_key("display_date")
      end
    end

    context "記事が存在しない場合" do
      it "404エラーを返す" do
        get "/api/v1/articles/99999"

        expect(response).to have_http_status(:not_found)
        expect(json_response["error"]).to eq("記事が見つかりません")
      end
    end

    context "不正なID形式の場合" do
      it "適切なエラーレスポンスを返す" do
        get "/api/v1/articles/invalid_id"

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  # TODO: 後で実装予定のアクション
  # describe "POST /create" do
  #   it "returns http success" do
  #     post "/api/v1/articles"
  #     expect(response).to have_http_status(:success)
  #   end
  # end

  # describe "PATCH /update" do
  #   it "returns http success" do
  #     patch "/api/v1/articles/1"
  #     expect(response).to have_http_status(:success)
  #   end
  # end

  # describe "DELETE /destroy" do
  #   it "returns http success" do
  #     delete "/api/v1/articles/1"
  #     expect(response).to have_http_status(:success)
  #   end
  # end
end

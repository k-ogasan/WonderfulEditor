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

  describe "POST /api/v1/articles" do
    let(:test_user) { create(:user, name: "テストユーザー", email: "test@example.com") }

    context "正常な記事作成" do
      it "記事作成時に正しいユーザーのIDが設定される" do
        # allow_any_instance_ofを使用してcurrent_userをテスト用ユーザーに設定
        allow_any_instance_of(Api::V1::BaseApiController).to receive(:current_user).and_return(test_user)

        post "/api/v1/articles", params: {
          article: {
            title: "テスト記事",
            body: "テスト記事の本文",
          },
        }

        expect(response).to have_http_status(:created)
        expect(json_response["title"]).to eq("テスト記事")
        expect(json_response["body"]).to eq("テスト記事の本文")
        expect(json_response["user"]["id"]).to eq(test_user.id)
        expect(json_response["user"]["name"]).to eq(test_user.name)
        expect(json_response["user"]["email"]).to eq(test_user.email)
      end

      it "作成された記事がデータベースに保存される" do
        allow_any_instance_of(Api::V1::BaseApiController).to receive(:current_user).and_return(test_user)

        expect {
          post "/api/v1/articles", params: {
            article: {
              title: "保存テスト記事",
              body: "保存テスト記事の本文",
            },
          }
        }.to change { Article.count }.by(1)

        # データベースに正しく保存されているか確認
        article = Article.last
        expect(article.title).to eq("保存テスト記事")
        expect(article.body).to eq("保存テスト記事の本文")
        expect(article.user_id).to eq(test_user.id)
      end
    end

    context "バリデーションエラー" do
      it "タイトルが空の場合、エラーが返される" do
        allow_any_instance_of(Api::V1::BaseApiController).to receive(:current_user).and_return(test_user)

        post "/api/v1/articles", params: {
          article: {
            title: "",
            body: "本文は入力済み",
          },
        }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response["errors"]).to include("タイトルは1文字以上で入力してください")
      end

      it "本文が空の場合、エラーが返される" do
        allow_any_instance_of(Api::V1::BaseApiController).to receive(:current_user).and_return(test_user)

        post "/api/v1/articles", params: {
          article: {
            title: "タイトルは入力済み",
            body: "",
          },
        }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response["errors"]).to include("本文は1文字以上で入力してください")
      end
    end

    context "異なるユーザーでの記事作成" do
      let(:another_user) { create(:user, name: "別のユーザー", email: "another@example.com") }

      it "異なるユーザーで記事作成が可能" do
        # 別のユーザーでcurrent_userを設定
        allow_any_instance_of(Api::V1::BaseApiController).to receive(:current_user).and_return(another_user)

        post "/api/v1/articles", params: {
          article: {
            title: "別ユーザーの記事",
            body: "別ユーザーの記事の本文",
          },
        }

        expect(response).to have_http_status(:created)
        expect(json_response["user"]["id"]).to eq(another_user.id)
        expect(json_response["user"]["name"]).to eq("別のユーザー")
      end
    end
  end

  describe "PATCH /api/v1/articles/:id" do
    let(:test_user) { create(:user, name: "テストユーザー", email: "test@example.com") }
    let(:article) { create(:article, user: test_user, title: "元のタイトル", body: "元の本文") }

    context "正常な記事更新" do
      it "記事の更新が成功する" do
        allow_any_instance_of(Api::V1::BaseApiController).to receive(:current_user).and_return(test_user)

        patch "/api/v1/articles/#{article.id}", params: {
          article: {
            title: "更新されたタイトル",
            body: "更新された本文",
          },
        }

        expect(response).to have_http_status(:ok)
        expect(json_response["title"]).to eq("更新されたタイトル")
        expect(json_response["body"]).to eq("更新された本文")
        expect(json_response["user"]["id"]).to eq(test_user.id)
      end
    end

    context "権限エラー" do
      let(:other_user) { create(:user, name: "他のユーザー", email: "other@example.com") }

      it "記事の所有者でない場合、権限エラーが返される" do
        allow_any_instance_of(Api::V1::BaseApiController).to receive(:current_user).and_return(other_user)

        patch "/api/v1/articles/#{article.id}", params: {
          article: {
            title: "更新しようとしたタイトル",
            body: "更新しようとした本文",
          },
        }

        expect(response).to have_http_status(:forbidden)
        expect(json_response["error"]).to eq("権限がありません")
      end
    end

    context "記事が見つからない場合" do
      it "404エラーが返される" do
        allow_any_instance_of(Api::V1::BaseApiController).to receive(:current_user).and_return(test_user)

        patch "/api/v1/articles/99999", params: {
          article: {
            title: "更新しようとしたタイトル",
            body: "更新しようとした本文",
          },
        }

        expect(response).to have_http_status(:not_found)
        expect(json_response["error"]).to eq("記事が見つかりません")
      end
    end
  end

  # TODO: 後で実装予定のアクション
  # describe "DELETE /destroy" do
  #   it "returns http success" do
  #     delete "/api/v1/articles/1"
  #     expect(response).to have_http_status(:success)
  #   end
  # end
end

require "rails_helper"

RSpec.describe "Api::V1::Articles", type: :request do
  describe "GET /index" do
    it "記事一覧を取得できる" do
      # テストデータを作成（公開記事として）
      article = create(:article, status: :published)

      # APIリクエストを送信
      get "/api/v1/articles"

      # レスポンスを確認
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_an(Array)
      expect(json_response.first["title"]).to eq(article.title)
      expect(json_response.first["updated_at"]).to be_present
    end

    it "公開記事のみが表示される" do
      # 公開記事と下書き記事を作成
      published_article = create(:article, status: :published)
      create(:article, status: :draft)

      get "/api/v1/articles"

      expect(response).to have_http_status(:ok)
      expect(json_response).to be_an(Array)
      expect(json_response.length).to eq(1)
      expect(json_response.first["id"]).to eq(published_article.id)
      expect(json_response.first["status"]).to eq("published")
    end
  end

  describe "GET /api/v1/articles/:id" do
    let(:user) { create(:user) }
    let(:article) { create(:article, user: user, status: :published) }

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

    context "下書き記事の場合" do
      let(:draft_article) { create(:article, user: user, status: :draft) }

      it "下書き記事は404エラーを返す" do
        get "/api/v1/articles/#{draft_article.id}"

        expect(response).to have_http_status(:not_found)
        expect(json_response["error"]).to eq("記事が見つかりません")
      end

      it "認証済みでも下書き記事は404エラーを返す" do
        auth_headers = user.create_new_auth_token

        get "/api/v1/articles/#{draft_article.id}", headers: auth_headers

        expect(response).to have_http_status(:not_found)
        expect(json_response["error"]).to eq("記事が見つかりません")
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
        # create_new_auth_tokenで認証トークンを生成
        auth_headers = test_user.create_new_auth_token

        post "/api/v1/articles",
             params: {
               article: {
                 title: "テスト記事",
                 body: "テスト記事の本文",
               },
             },
             headers: auth_headers

        expect(response).to have_http_status(:created)
        expect(json_response["title"]).to eq("テスト記事")
        expect(json_response["body"]).to eq("テスト記事の本文")
        expect(json_response["user"]["id"]).to eq(test_user.id)
        expect(json_response["user"]["name"]).to eq(test_user.name)
        expect(json_response["user"]["email"]).to eq(test_user.email)
      end

      it "作成された記事がデータベースに保存される" do
        auth_headers = test_user.create_new_auth_token

        expect {
          post "/api/v1/articles",
               params: {
                 article: {
                   title: "保存テスト記事",
                   body: "保存テスト記事の本文",
                 },
               },
               headers: auth_headers
        }.to change { Article.count }.by(1)

        # データベースに正しく保存されているか確認
        article = Article.last
        expect(article.title).to eq("保存テスト記事")
        expect(article.body).to eq("保存テスト記事の本文")
        expect(article.user_id).to eq(test_user.id)
        expect(article.draft?).to be true
      end

      it "下書き記事として保存できる" do
        auth_headers = test_user.create_new_auth_token

        post "/api/v1/articles",
             params: {
               article: {
                 title: "下書き記事",
                 body: "下書き記事の本文",
                 status: "draft",
               },
             },
             headers: auth_headers

        expect(response).to have_http_status(:created)
        expect(json_response["status"]).to eq("draft")
        expect(json_response["published_at"]).to be_nil
      end

      it "公開記事として保存できる" do
        auth_headers = test_user.create_new_auth_token

        post "/api/v1/articles",
             params: {
               article: {
                 title: "公開記事",
                 body: "公開記事の本文",
                 status: "published",
               },
             },
             headers: auth_headers

        expect(response).to have_http_status(:created)
        expect(json_response["status"]).to eq("published")
        expect(json_response["published_at"]).to be_present
      end
    end

    context "バリデーションエラー" do
      it "タイトルが空の場合、エラーが返される" do
        auth_headers = test_user.create_new_auth_token

        post "/api/v1/articles",
             params: {
               article: {
                 title: "",
                 body: "本文は入力済み",
               },
             },
             headers: auth_headers

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response["errors"]).to include("Title can't be blank")
      end

      it "本文が空の場合、エラーが返される" do
        auth_headers = test_user.create_new_auth_token

        post "/api/v1/articles",
             params: {
               article: {
                 title: "タイトルは入力済み",
                 body: "",
               },
             },
             headers: auth_headers

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response["errors"]).to include("Body can't be blank")
      end
    end

    context "異なるユーザーでの記事作成" do
      let(:another_user) { create(:user, name: "別のユーザー", email: "another@example.com") }

      it "異なるユーザーで記事作成が可能" do
        # 別のユーザーでcurrent_userを設定
        auth_headers = another_user.create_new_auth_token

        post "/api/v1/articles",
             params: {
               article: {
                 title: "別ユーザーの記事",
                 body: "別ユーザーの記事の本文",
               },
             },
             headers: auth_headers

        expect(response).to have_http_status(:created)
        expect(json_response["user"]["id"]).to eq(another_user.id)
        expect(json_response["user"]["name"]).to eq("別のユーザー")
      end
    end
  end

  describe "PATCH /api/v1/articles/:id" do
    let(:test_user) { create(:user, name: "テストユーザー", email: "test@example.com") }
    let(:article) { create(:article, user: test_user, title: "元のタイトル", body: "元の本文", status: :published) }

    context "正常な記事更新" do
      it "記事の更新が成功する" do
        auth_headers = test_user.create_new_auth_token

        patch "/api/v1/articles/#{article.id}",
              params: {
                article: {
                  title: "更新されたタイトル",
                  body: "更新された本文",
                },
              },
              headers: auth_headers

        expect(response).to have_http_status(:ok)
        expect(json_response["title"]).to eq("更新されたタイトル")
        expect(json_response["body"]).to eq("更新された本文")
        expect(json_response["user"]["id"]).to eq(test_user.id)
      end

      it "下書きから公開に変更できる" do
        auth_headers = test_user.create_new_auth_token
        draft_article = create(:article, user: test_user, status: :draft)

        patch "/api/v1/articles/#{draft_article.id}",
              params: {
                article: {
                  status: "published",
                },
              },
              headers: auth_headers

        expect(response).to have_http_status(:ok)
        expect(json_response["status"]).to eq("published")
        expect(json_response["published_at"]).to be_present
      end

      it "公開から下書きに変更できる" do
        auth_headers = test_user.create_new_auth_token
        published_article = create(:article, user: test_user, status: :published)

        patch "/api/v1/articles/#{published_article.id}",
              params: {
                article: {
                  status: "draft",
                },
              },
              headers: auth_headers

        expect(response).to have_http_status(:ok)
        expect(json_response["status"]).to eq("draft")
      end
    end

    context "権限エラー" do
      let(:other_user) { create(:user, name: "他のユーザー", email: "other@example.com") }

      it "記事の所有者でない場合、権限エラーが返される" do
        auth_headers = other_user.create_new_auth_token

        patch "/api/v1/articles/#{article.id}",
              params: {
                article: {
                  title: "更新しようとしたタイトル",
                  body: "更新しようとした本文",
                },
              },
              headers: auth_headers

        expect(response).to have_http_status(:forbidden)
        expect(json_response["error"]).to eq("権限がありません")
      end
    end

    context "記事が見つからない場合" do
      it "404エラーが返される" do
        auth_headers = test_user.create_new_auth_token

        patch "/api/v1/articles/99999",
              params: {
                article: {
                  title: "更新しようとしたタイトル",
                  body: "更新しようとした本文",
                },
              },
              headers: auth_headers

        expect(response).to have_http_status(:not_found)
        expect(json_response["error"]).to eq("記事が見つかりません")
      end
    end
  end

  describe "DELETE /api/v1/articles/:id" do
    let(:test_user) { create(:user, name: "テストユーザー", email: "test@example.com") }
    let!(:article) { create(:article, user: test_user, title: "削除対象の記事", body: "削除対象の記事の本文", status: :published) }

    context "正常な記事削除" do
      it "記事の削除が成功する" do
        auth_headers = test_user.create_new_auth_token

        expect {
          delete "/api/v1/articles/#{article.id}", headers: auth_headers
        }.to change { Article.count }.by(-1)

        expect(response).to have_http_status(:no_content)
      end
    end

    context "権限エラー" do
      let(:other_user) { create(:user, name: "他のユーザー", email: "other@example.com") }

      it "記事の所有者でない場合、権限エラーが返される" do
        auth_headers = other_user.create_new_auth_token

        delete "/api/v1/articles/#{article.id}", headers: auth_headers

        expect(response).to have_http_status(:forbidden)
        expect(json_response["error"]).to eq("権限がありません")
      end
    end

    context "記事が見つからない場合" do
      it "404エラーが返される" do
        auth_headers = test_user.create_new_auth_token

        delete "/api/v1/articles/99999", headers: auth_headers

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "GET /api/v1/articles/drafts" do
    let(:test_user) { create(:user, name: "テストユーザー", email: "test@example.com") }

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
        create(:article, user: other_user, status: :draft, title: "他人の下書き")
        create(:article, user: test_user, status: :draft, title: "自分の下書き")

        get "/api/v1/articles/drafts", headers: auth_headers

        expect(response).to have_http_status(:ok)
        expect(json_response.length).to eq(1)
        expect(json_response.first["title"]).to eq("自分の下書き")
      end
    end

    context "認証なしの場合" do
      it "401エラーが返される" do
        get "/api/v1/articles/drafts"

        expect(response).to have_http_status(:unauthorized)
      end
    end
    describe "GET /api/v1/articles/:id/draft" do
      let(:test_user) { create(:user, name: "テストユーザー", email: "test@example.com") }

      context "認証済みユーザーの場合" do
        it "自分の下書き記事詳細を取得できる" do
          auth_headers = test_user.create_new_auth_token
          draft_article = create(:article, user: test_user, status: :draft, title: "下書き記事詳細", body: "下書き記事の本文")

          get "/api/v1/articles/#{draft_article.id}/draft", headers: auth_headers

          expect(response).to have_http_status(:ok)
          expect(json_response["id"]).to eq(draft_article.id)
          expect(json_response["title"]).to eq("下書き記事詳細")
          expect(json_response["body"]).to eq("下書き記事の本文")
          expect(json_response["status"]).to eq("draft")
          expect(json_response["published_at"]).to be_nil
          expect(json_response["user"]["id"]).to eq(test_user.id)
        end

        it "他のユーザーの下書き記事は取得できない" do
          auth_headers = test_user.create_new_auth_token
          other_user = create(:user)
          other_draft = create(:article, user: other_user, status: :draft, title: "他人の下書き")

          get "/api/v1/articles/#{other_draft.id}/draft", headers: auth_headers

          expect(response).to have_http_status(:not_found)
          expect(json_response["error"]).to eq("下書き記事が見つかりません")
        end

        it "存在しない下書き記事IDの場合は404エラー" do
          auth_headers = test_user.create_new_auth_token

          get "/api/v1/articles/99999/draft", headers: auth_headers

          expect(response).to have_http_status(:not_found)
          expect(json_response["error"]).to eq("下書き記事が見つかりません")
        end

        it "公開記事のIDを指定しても404エラー" do
          auth_headers = test_user.create_new_auth_token
          published_article = create(:article, user: test_user, status: :published, title: "公開記事")

          get "/api/v1/articles/#{published_article.id}/draft", headers: auth_headers

          expect(response).to have_http_status(:not_found)
          expect(json_response["error"]).to eq("下書き記事が見つかりません")
        end

        it "不正なID形式の場合は404エラー" do
          auth_headers = test_user.create_new_auth_token

          get "/api/v1/articles/invalid_id/draft", headers: auth_headers

          expect(response).to have_http_status(:not_found)
        end
      end

      context "認証なしの場合" do
        it "401エラーが返される" do
          draft_article = create(:article, status: :draft)

          get "/api/v1/articles/#{draft_article.id}/draft"

          expect(response).to have_http_status(:unauthorized)
        end
      end
    end
  end

  describe "GET /api/v1/current/articles" do
    let(:test_user) { create(:user, name: "テストユーザー", email: "test@example.com") }

    context "認証済みユーザーの場合" do
      it "自分の公開記事一覧を取得できる" do
        auth_headers = test_user.create_new_auth_token
        published_article1 = create(:article, user: test_user, status: :published, title: "公開記事1")
        published_article2 = create(:article, user: test_user, status: :published, title: "公開記事2")
        draft_article = create(:article, user: test_user, status: :draft, title: "下書き記事")

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
        other_published = create(:article, user: other_user, status: :published, title: "他人の公開記事")
        my_published = create(:article, user: test_user, status: :published, title: "自分の公開記事")

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
    end

    context "認証なしの場合" do
      it "401エラーが返される" do
        get "/api/v1/current/articles"

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end

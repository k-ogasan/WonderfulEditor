# == Schema Information
#
# Table name: articles
#
#  id           :bigint           not null, primary key
#  body         :text
#  published_at :datetime
#  status       :integer          default("draft"), not null
#  title        :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  user_id      :bigint           not null
#
# Indexes
#
#  index_articles_on_published_at  (published_at)
#  index_articles_on_status        (status)
#  index_articles_on_user_id       (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
require "rails_helper"

RSpec.describe Article, type: :model do
  context "タイトルが1文字以上、75文字未満だった時" do
    it "記事が作られる" do
      article = FactoryBot.create(:article)
      expect(article).to be_valid
    end
  end

  context "タイトルが75文字以上だった時" do
    it "公開記事は作成できない" do
      long_title = "a" * 76 # 76文字のタイトル
      article = FactoryBot.build(:article, title: long_title, status: :published) # 公開記事を作成
      expect(article).not_to be_valid # 記事が無効であることを期待
    end

    it "下書き記事は作成できる" do
      long_title = "a" * 76 # 76文字のタイトル
      article = FactoryBot.build(:article, title: long_title, status: :draft) # 下書き記事を作成
      expect(article).to be_valid # 下書き記事は有効であることを期待
    end
  end

  context "本文が1文字以上、200文字未満だった時" do
    it "記事が作られる" do
      article = FactoryBot.build(:article) # ファクトリーから記事を生成
      expect(article).to be_valid # 記事が有効であることを期待
    end
  end

  context "本文が200文字以上だった場合" do
    it "公開記事は作成できない" do
      long_body = "a" * 201 # 本文が201文字
      article = FactoryBot.build(:article, body: long_body, status: :published) # 公開記事を作成
      expect(article).not_to be_valid
    end

    it "下書き記事は作成できる" do
      long_body = "a" * 201 # 本文が201文字
      article = FactoryBot.build(:article, body: long_body, status: :draft) # 下書き記事を作成
      expect(article).to be_valid
    end
  end

  describe "下書き機能" do
    context "下書き記事として保存" do
      it "下書き記事が作成できる" do
        article = FactoryBot.build(:article, status: :draft)
        expect(article).to be_valid
        expect(article.draft?).to be true
      end

      it "下書き記事はタイトルと本文が必須" do
        article = FactoryBot.build(:article, status: :draft, title: "", body: "")
        expect(article).not_to be_valid
        expect(article.errors[:title]).to include("can't be blank")
        expect(article.errors[:body]).to include("can't be blank")
      end

      it "下書き記事は長さ制限が適用されない" do
        long_title = "a" * 100
        long_body = "a" * 300
        article = FactoryBot.build(:article, status: :draft, title: long_title, body: long_body)
        expect(article).to be_valid
      end
    end

    context "公開記事として保存" do
      it "公開記事が作成できる" do
        article = FactoryBot.build(:article, status: :published)
        expect(article).to be_valid
        expect(article.published?).to be true
      end

      it "公開記事はタイトルと本文の長さ制限が適用される" do
        long_title = "a" * 76
        long_body = "a" * 201
        article = FactoryBot.build(:article, status: :published, title: long_title, body: long_body)
        expect(article).not_to be_valid
        expect(article.errors[:title]).to include("is too long (maximum is 75 characters)")
        expect(article.errors[:body]).to include("is too long (maximum is 200 characters)")
      end

      it "公開時にpublished_atが自動設定される" do
        article = FactoryBot.build(:article, status: :draft)
        article.save!

        expect(article.published_at).to be_nil

        article.update!(status: :published)
        expect(article.published_at).to be_present
        expect(article.published_at).to be_within(1.second).of(Time.current)
      end
    end

    context "スコープ" do
      let!(:draft_article) { FactoryBot.create(:article, status: :draft) }
      let!(:published_article) { FactoryBot.create(:article, status: :published) }

      it "publishedスコープが正しく動作する" do
        published_articles = Article.published
        expect(published_articles).to include(published_article)
        expect(published_articles).not_to include(draft_article)
      end

      it "draftスコープが正しく動作する" do
        draft_articles = Article.draft
        expect(draft_articles).to include(draft_article)
        expect(draft_articles).not_to include(published_article)
      end
    end
  end
end

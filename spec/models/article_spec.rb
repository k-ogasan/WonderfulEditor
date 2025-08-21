# == Schema Information
#
# Table name: articles
#
#  id         :bigint           not null, primary key
#  body       :text
#  title      :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :bigint           not null
#
# Indexes
#
#  index_articles_on_user_id  (user_id)
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
    it "記事が作成できない" do
      long_title = "a" * 76 # 76文字のタイトル
      article = FactoryBot.build(:article, title: long_title) # 記事を作成
      expect(article).not_to be_valid # 記事が無効であることを期待
    end
  end

  context "本文が1文字以上、200文字未満だった時" do
    it "記事が作られる" do
      article = FactoryBot.build(:article) # ファクトリーから記事を生成
      expect(article).to be_valid # 記事が有効であることを期待
    end
  end

  context "本文が200文字以上だった場合" do
    it "記事が作成できない" do
      long_body = "a" * 201 # 本文が201文字
      article = FactoryBot.build(:article, body: long_body) # ファクトリーから記事を生成
      expect(article).not_to be_valid
    end
  end
end

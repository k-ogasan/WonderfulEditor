# == Schema Information
#
# Table name: comments
#
#  id         :bigint           not null, primary key
#  body       :text
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  article_id :bigint           not null
#  user_id    :bigint           not null
#
# Indexes
#
#  index_comments_on_article_id  (article_id)
#  index_comments_on_user_id     (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (article_id => articles.id)
#  fk_rails_...  (user_id => users.id)
#
require "rails_helper"

RSpec.describe Comment, type: :model do
  let(:user) { FactoryBot.create(:user) } # 必要なユーザーを作成
  let(:article) { FactoryBot.create(:article) } # 必要な記事を作成

  context "本文が1文字以上、75文字未満だった時" do
    it "コメントが作られる" do
      comment = Comment.new(body: "テストコメント", user: user, article: article)
      expect(comment).to be_valid
    end
  end

  context "本文が75文字以上だった時" do
    it "記事が作成できない" do
      long_body = "a" * 76 # 76文字の文字列を作成
      comment = Comment.new(body: long_body, user: user, article: article)
      expect(comment).not_to be_valid
    end
  end

  context "ボディが空のとき" do
    it "無効なコメントが作成される" do
      comment = Comment.new(body: nil, user: user, article: article)
      expect(comment).not_to be_valid
    end
  end
end

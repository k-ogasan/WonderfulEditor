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
FactoryBot.define do
  factory :article do
    association :user
    title { Faker::Lorem.sentence(word_count: 75)[0..74] } # 1〜75ワードの文を生成し、75文字以内に切り取る
    body { Faker::Lorem.characters(number: rand(1..199)) } # 1〜199文字のランダムな文字列
  end
end

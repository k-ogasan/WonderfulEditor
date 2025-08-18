FactoryBot.define do
  factory :user do
    name { Faker::Name.name } # ランダムな名前
    email { Faker::Internet.email } # ランダムなメールアドレス
    password { 'password123' } # パスワードは固定でも良い
  end
end

require "rails_helper"

RSpec.describe User, type: :model do
  context "name が存在する時" do
    it "ユーザーが作られる" do
      user = FactoryBot.build(:user)
      expect(user).to be_valid
    end
  end

  context "name が存在しない時" do
   it "ユーザーが作成できない" do
    user = FactoryBot.build(:user, name: nil) # nameをnilに設定
    expect(user).to_not be_valid # ユーザーが無効であることを期待
    expect(user.errors[:name]).to include("can't be blank") # エラーメッセージも確認
   end
  end
  context "同じnameが存在しない場合" do
    it "ユーザーが作られる" do
      user = FactoryBot.build(:user)
      expect(user).to be_valid
    end
  end

  context "同じnameが存在する場合" do
    it "ユーザーが作成できない" do
     create(:user, name: "foo")
      user = FactoryBot.build(:user, name: "foo")
      #  binding.pry
      expect(user).to be_invalid
      expect(user.errors.details[:name][0][:error]).to eq :taken
      # expect(user.errors[:name]).to include("can't be blank")
    end
  end
end

class Api::V1::BaseApiController < ApplicationController
  # API用のレスポンス形式を設定
  respond_to :json

  private

  def current_user
    # 仮実装: usersテーブルの一番初めのユーザーを返す
    User.first
  end
end

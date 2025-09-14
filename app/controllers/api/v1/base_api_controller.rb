class Api::V1::BaseApiController < ApplicationController
  # API用のレスポンス形式を設定
  respond_to :json

  private

    def current_user
      # devise_token_authの認証されたユーザーを返す
      current_api_v1_user
    end

    def authenticate_user!
      # devise_token_authの認証メソッドを使用
      authenticate_api_v1_user!
    end

    def user_signed_in?
      # devise_token_authの認証状態を確認
      current_api_v1_user.present?
    end
end

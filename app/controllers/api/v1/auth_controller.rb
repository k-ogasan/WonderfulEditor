class Api::V1::AuthController < DeviseTokenAuth::SessionsController
  def destroy
    # 認証ヘッダーが存在するかチェック
    unless request.headers["access-token"] && request.headers["client"] && request.headers["uid"]
      render json: { error: "認証ヘッダーが不足しています" }, status: :unauthorized
      return
    end

    # ユーザーが認証されているかチェック
    unless current_api_v1_user
      render json: { error: "無効な認証トークンです" }, status: :unauthorized
      return
    end

    # 正常なログアウト処理
    current_api_v1_user.tokens.delete(request.headers["client"])
    current_api_v1_user.save!

    render json: { success: true, message: "ログアウトしました" }, status: :ok
  end
end

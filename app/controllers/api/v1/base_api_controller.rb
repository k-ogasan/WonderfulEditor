class Api::V1::BaseApiController < ApplicationController
  # API用のレスポンス形式を設定
  respond_to :json
end

class Api::V1::Current::ArticlesController < Api::V1::BaseApiController
  before_action :authenticate_user!

  def index
    articles = current_user.articles.published.order(updated_at: :desc)
    render json: articles, each_serializer: Api::V1::ArticlePreviewSerializer
  end
end

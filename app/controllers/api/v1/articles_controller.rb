class Api::V1::ArticlesController < Api::V1::BaseApiController
  # 記事一覧と記事詳細は認証不要、その他は認証が必要
  before_action :authenticate_api_v1_user!, except: [:index, :show]

  def index
    articles = Article.order(updated_at: :desc)
    render json: articles, each_serializer: Api::V1::ArticlePreviewSerializer
  end

  def show
    article = Article.find(params[:id])
    render json: article, serializer: Api::V1::ArticleDetailSerializer
  rescue ActiveRecord::RecordNotFound
    render json: { error: "記事が見つかりません" }, status: :not_found
  end

  def create
    # current_userを使用して記事を作成
    article = current_user.articles.build(article_params)

    if article.save
      render json: article, serializer: Api::V1::ArticleDetailSerializer, status: :created
    else
      render json: { errors: article.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
  end

  def destroy
  end

  private

    def article_params
      # 許可するパラメータを制限
      params.require(:article).permit(:title, :body)
    end
end

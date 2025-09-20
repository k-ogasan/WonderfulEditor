class Api::V1::ArticlePreviewSerializer < ActiveModel::Serializer
  attributes :id, :title, :updated_at, :status, :published_at, :comments_count, :likes_count

  belongs_to :user, serializer: Api::V1::UserSerializer

  def comments_count
    object.comments.count
  end

  def likes_count
    object.article_likes.count
  end
end

class Api::V1::ArticlePreviewSerializer < ActiveModel::Serializer
  attributes :id, :title, :updated_at, :comments_count, :likes_count

  belongs_to :user, serializer: Api::V1::UserSerializer

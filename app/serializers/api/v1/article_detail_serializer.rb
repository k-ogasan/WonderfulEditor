class Api::V1::ArticleDetailSerializer < ActiveModel::Serializer
  attributes :id, :title, :body, :updated_at

  belongs_to :user, serializer: Api::V1::UserSerializer
end

class Api::V1::UserSerializer < ActiveModel::Serializer
  attributes :id, :name, :email, :created_at, :articles_count
end

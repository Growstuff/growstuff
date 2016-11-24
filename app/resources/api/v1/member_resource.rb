class Api::V1::MemberResource < JSONAPI::Resource
  attributes :login_name, :bio, :preferred_avatar_uri
  has_many :gardens
  has_many :plantings
  has_many :posts
  has_many :seeds
end

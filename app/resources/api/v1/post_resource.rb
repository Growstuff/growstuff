class Api::V1::PostResource < JSONAPI::Resource
  attributes :subject, :body, :created_at
  has_one :author
end

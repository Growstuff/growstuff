# frozen_string_literal: true
class Api::V1::CommentResource < JSONAPI::Resource
  attributes :body, :created_at
  has_one :post
  has_one :author
end

# frozen_string_literal: true

class MemberResource < ApplicationResource
  self.model = Member
  primary_endpoint '/members', %i(index show)

  attribute :login_name, :string, writable: false
  attribute :slug, :string, writable: false

  has_many :gardens, foreign_key: :owner_id
  has_many :plantings, foreign_key: :owner_id
  has_many :harvests, foreign_key: :owner_id
  has_many :seeds, foreign_key: :owner_id
  has_many :jobs, foreign_key: :owner_id
  has_many :photos, foreign_key: :owner_id
end

# frozen_string_literal: true

class MemberResource < ApplicationResource
  self.model = Member
  read_only

  attribute :login_name, :string
  attribute :slug, :string

  has_many :gardens, foreign_key: :owner_id
  has_many :plantings, foreign_key: :owner_id
  has_many :harvests, foreign_key: :owner_id
  has_many :seeds, foreign_key: :owner_id
  has_many :jobs, foreign_key: :owner_id
  has_many :photos, foreign_key: :owner_id
end

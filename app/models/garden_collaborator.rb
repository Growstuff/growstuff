# frozen_string_literal: true

class GardenCollaborator < ApplicationRecord
  belongs_to :member
  belongs_to :garden

  validates :member_id, uniqueness: { scope: :garden }

  def member_slug
    @member&.slug
  end

  def member_slug=(_slug)
    member_slug
  end
end

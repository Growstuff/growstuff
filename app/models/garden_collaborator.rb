# frozen_string_literal: true

class GardenCollaborator < ApplicationRecord
  belongs_to :member
  belongs_to :garden

  validates :member_id, uniqueness: { scope: :garden }
  validate :not_garden_owner

  def not_garden_owner
    return unless member
    return unless garden

    errors.add(:member_id, "cannot be the garden owner") if garden.owner == member
  end

  def member_slug
    @member&.slug
  end

  def member_slug=(_slug)
    member_slug
  end
end

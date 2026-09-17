# frozen_string_literal: true

class Block < ApplicationRecord
  belongs_to :blocker, class_name: "Member"
  belongs_to :blocked, class_name: "Member"

  validates :blocker_id, uniqueness: { scope: :blocked_id }

  after_create :destroy_follow_relationship

  private

  def destroy_follow_relationship
    # Destroy the follow relationship in both directions
    Follow.where(follower: blocker, followed: blocked).destroy_all
    Follow.where(follower: blocked, followed: blocker).destroy_all
  end
end

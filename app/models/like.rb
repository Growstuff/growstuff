# frozen_string_literal: true

class Like < ApplicationRecord
  belongs_to :member
  belongs_to :likeable, polymorphic: true, counter_cache: true, touch: true
  validates :member, :likeable, presence: true
  validates :member, uniqueness: { scope: :likeable }
  validate :member_is_not_blocked

  def likeable_author
    if likeable.respond_to?(:author)
      likeable.author
    elsif likeable.respond_to?(:owner)
      likeable.owner
    end
  end

  private

  def member_is_not_blocked
    return unless member
    author = likeable_author
    if author && author.already_blocking?(member)
      errors.add(:base, "You cannot like content of a member who has blocked you.")
    end
  end
end

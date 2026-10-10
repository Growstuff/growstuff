# frozen_string_literal: true

module Likeable
  extend ActiveSupport::Concern

  included do
    has_many :likes, as: :likeable, inverse_of: :likeable, dependent: :delete_all
    has_many :members, through: :likes
  end

  def liked_by?(member)
    return false unless member

    likes.exists?(member_id: member.id)
  end

  def liked_by_members_names
    members.pluck(:login_name)
  end
end

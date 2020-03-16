# frozen_string_literal: true

module Likeable
  extend ActiveSupport::Concern

  included do
    has_many :likes, as: :likeable, inverse_of: :likeable, dependent: :delete_all
    has_many :members, through: :likes
  end

  def liked_by?(member)
    liked_by_members_names.include?(member.login_name)
  end

  def liked_by_members_names
    Member.where(id: likes.pluck(:member_id)).pluck(:login_name)
  end
end

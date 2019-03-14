# frozen_string_literal: true

class Forum < ApplicationRecord
  extend FriendlyId
  include Ownable
  validates :name, presence: true
  friendly_id :name, use: %i(slugged finders)

  has_many :posts, dependent: :destroy

  def to_s
    name
  end
end

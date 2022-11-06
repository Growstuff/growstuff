# frozen_string_literal: true

class GardenType < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: %i(slugged finders)

  has_many :gardens, dependent: :nullify

  validates :name, presence: true, uniqueness: true
  validates :slug, presence: true, uniqueness: true

  def garden_type_slug
    name.gsub!(/[^A-Za-z]/, '')
  end

  def subtitler(garden_type)
    num = garden_type.gardens.uniq.count
    s = num > 1 || num.zero? ? "s are" : " is"
    "#{num} garden#{s} using this garden type"
  end
end

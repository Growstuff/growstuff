# frozen_string_literal: true

class Activity < ApplicationRecord
  include Ownable
  include Finishable

  belongs_to :garden, optional: true
  belongs_to :planting, optional: true

  CATEGORIES = ["General", "Weeding", "Soil Cultivation", "Fertilizing", "Pruning", "Watering"]

  validates :name, presence: true
  validates :category, inclusion: { in: CATEGORIES }, presence: true
  validates :owner, presence: true

  def to_s
    name
  end
end

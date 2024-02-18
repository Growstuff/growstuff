# frozen_string_literal: true

class Activity < ApplicationRecord
  include Ownable
  include Finishable

  CATEGORIES = ["General", "Weeding", "Soil Cultivation", "Fertilizing", "Pruning"]

  validates :name, presence: true
  validates :category, inclusion: { in: CATEGORIES }, presence: true
  validates :owner, presence: true

  def to_s
    name
  end
end

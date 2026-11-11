# frozen_string_literal: true

class SoilPhReading < ApplicationRecord
  belongs_to :garden

  validates :measured_on, presence: true
  validates :ph, presence: true, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 14 }

  scope :newest_first, -> { order(measured_on: :desc, id: :desc) }
end

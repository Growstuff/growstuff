# A weather observation is intended to be a snapshot aligned to
# https://github.com/schemaorg/schemaorg/issues/362
class WeatherObservation < ApplicationRecord
  belongs_to :garden

  validates :source, presence: true
  validates :observed_at, presence: true
end
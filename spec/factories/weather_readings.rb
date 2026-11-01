# frozen_string_literal: true

FactoryBot.define do
  factory :weather_reading do
    latitude { -41.25 }
    longitude { 174.75 }
    date { Date.new(2026, 10, 1) }
    source { 'open-meteo' }
    rainfall_mm { 2.0 }
    temp_max_c { 15.0 }
    temp_min_c { 8.0 }
  end
end

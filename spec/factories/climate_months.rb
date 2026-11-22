# frozen_string_literal: true

FactoryBot.define do
  factory :climate_month do
    latitude { -41.25 }
    longitude { 174.75 }
    year { 2025 }
    month { 7 }
    days { 31 }
    rain_mm { 145.0 }
    temp_mean_c { 9.0 }
    temp_max_c { 15.0 }
    temp_max_on { Date.new(2025, 7, 20) }
    temp_min_c { 1.0 }
    temp_min_on { Date.new(2025, 7, 14) }
    soil_temp_c { 7.5 }
    soil_temp_max_c { 9.0 }
    soil_temp_max_on { Date.new(2025, 7, 25) }
    soil_temp_min_c { 6.0 }
    soil_temp_min_on { Date.new(2025, 7, 15) }
  end
end

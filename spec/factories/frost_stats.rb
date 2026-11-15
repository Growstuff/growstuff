# frozen_string_literal: true

FactoryBot.define do
  factory :frost_stat do
    latitude { -41.25 }
    longitude { 174.75 }
    threshold_c { 0.0 }
    status { 'frost' }
    years_used { 30 }
    frost_years { 30 }
    first_frost_median { 150 }
    first_frost_p10 { 130 }
    last_frost_median { 250 }
    last_frost_p90 { 270 }
    frost_free_days_median { 280 }
    computed_at { Time.zone.now }
  end
end

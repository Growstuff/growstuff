# frozen_string_literal: true

FactoryBot.define do
  factory :climate_recent do
    latitude { -41.25 }
    longitude { 174.75 }
    starts_on { Date.new(2026, 2, 20) }
    ends_on { Date.new(2026, 3, 21) }
    days { 30 }
    temp_mean_c { 17.0 }
  end
end

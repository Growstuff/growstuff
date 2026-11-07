# frozen_string_literal: true

FactoryBot.define do
  factory :frost_year do
    latitude { -41.25 }
    longitude { 174.75 }
    threshold_c { 0.0 }
    sequence(:year) { |n| 1990 + n }
    first_frost { Date.new(year, 5, 20) }
    last_frost { Date.new(year, 9, 10) }
    lowest_c { -2.5 }
  end
end

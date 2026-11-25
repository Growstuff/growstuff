# frozen_string_literal: true

FactoryBot.define do
  factory :place_condition do
    latitude { -41.25 }
    longitude { 174.75 }
    kind { 'frost' }
    occurred_on { Date.new(2026, 5, 2) }
    value { -1.0 }
    threshold { 2.0 }
  end
end

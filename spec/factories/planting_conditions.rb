# frozen_string_literal: true

FactoryBot.define do
  factory :planting_condition do
    planting
    kind { 'frost' }
    occurred_on { Date.new(2026, 5, 2) }
    value { -1.0 }
  end
end

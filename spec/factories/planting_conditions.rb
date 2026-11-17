# frozen_string_literal: true

FactoryBot.define do
  factory :planting_condition do
    planting
    kind { 'killing_cold' }
    occurred_on { Date.new(2026, 5, 2) }
    value { -4.0 }
    threshold { -2.0 }
  end
end

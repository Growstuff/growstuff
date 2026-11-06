# frozen_string_literal: true

FactoryBot.define do
  factory :stall do
    member
    opened_at { nil }

    trait :open do
      opened_at { Time.zone.local(2026, 11, 1, 12) }
    end
  end
end

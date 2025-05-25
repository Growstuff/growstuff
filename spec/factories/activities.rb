# frozen_string_literal: true

FactoryBot.define do
  factory :activity do
    association :owner, factory: :member
    sequence(:name) { |n| "Test Activity #{n}" }
    description { "This is a test activity." }
    category { "General" } # Example category
    due_date { Time.zone.today + 1.week }

    # Optional associations, uncomment and adjust if Activity model has these
    # association :garden, factory: :garden
    # association :planting, factory: :planting

    trait :finished do
      finished { true }
    end
  end
end

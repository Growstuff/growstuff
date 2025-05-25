# frozen_string_literal: true

FactoryBot.define do
  factory :planting do
    association :owner, factory: :member
    association :crop
    association :garden
    planted_at { Time.zone.today - 1.month }
    description { "My awesome planting." }
    quantity { 1 } # Example attribute

    # Add traits if needed
    trait :finished do
      finished { true }
      finished_at { Time.zone.today - 1.day }
    end
  end
end

# Assuming Crop and Garden factories are needed and might not exist
# Minimal Crop factory
FactoryBot.define do
  factory :crop do
    sequence(:name) { |n| "Test Crop #{n}" }
    # Add other necessary attributes for Crop
    # e.g., approval_status if relevant for comments
    approval_status { 'approved' } # Default to approved for simplicity
  end
end

# Minimal Garden factory
FactoryBot.define do
  factory :garden do
    association :owner, factory: :member
    sequence(:name) { |n| "Test Garden #{n}" }
    # Add other necessary attributes for Garden
  end
end

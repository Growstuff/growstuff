# frozen_string_literal: true

FactoryBot.define do
  factory :member do
    sequence(:login_name) { |n| "member#{n}" }
    sequence(:email) { |n| "member#{n}@example.com" }
    password { "password123" }
    password_confirmation { "password123" }
    confirmed_at { Time.zone.now } # Assuming Devise confirmable is used

    trait :admin do
      after(:create) { |member| member.add_role(:admin) }
    end

    # Add other traits if needed, e.g., for specific member states or roles
  end
end

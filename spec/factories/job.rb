# frozen_string_literal: true

# Read about factories at https://github.com/thoughtbot/factory_bot

FactoryBot.define do
  factory :job do
    name { "Admire" }
    description { "Spend 10 minutes admiring your hard work" }
    owner

    trait :garden do
      description { "Apply compost from winter" }
      due_date { 3.months.from_now }
      garden
    end

    trait :planting do
      description { "Stake tomato" }
      # A job can only be about its owner's own planting.
      planting { association :planting, owner: }
    end
  end
end

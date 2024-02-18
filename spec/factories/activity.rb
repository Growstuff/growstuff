# frozen_string_literal: true

# Read about factories at https://github.com/thoughtbot/factory_bot

FactoryBot.define do
    factory :activity do
      name { "Admire" }
      description { "Spend 10 minutes admiring your hard work" }
      category { "General" }
      owner
  
      trait :garden do
        category { "Soil Cultivation" }
        description { "Apply compost from winter" }
        due_date { 3.months.from_now }
        garden
      end

      trait :planting do
        category { "Pruning" }
        description { "Stake tomato" }
        planting
      end
    end
  end
  
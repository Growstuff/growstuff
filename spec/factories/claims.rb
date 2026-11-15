# frozen_string_literal: true

FactoryBot.define do
  factory :claim do
    stall_seed
    member

    # A friend asking for a seedling on offer.
    trait :for_seedling do
      stall_seed { nil }
      stall_planting { association :stall_planting, :offered, strategy: :create }
    end
  end
end

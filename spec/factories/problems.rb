# frozen_string_literal: true

FactoryBot.define do
  factory :problem do
    sequence(:title) { |n| "Problem #{n}" }
    description { "Sample description of the problem" }
    problem_type { "Disease" }

    trait :pest do
      problem_type { "Pest" }
    end

    trait :general do
      problem_type { "General" }
    end
  end
end

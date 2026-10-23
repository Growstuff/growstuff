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

    # Done before the time a job was crossed off was recorded: only its due date says when.
    trait :finished_without_time do
      finished { true }
      after(:create) { |job| job.update_columns(finished_at: nil) } # rubocop:disable Rails/SkipsModelValidations
    end

    trait :planting do
      description { "Stake tomato" }
      # A job can only be about its owner's own planting.
      planting { association :planting, owner: }
    end
  end
end

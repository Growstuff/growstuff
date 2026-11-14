# frozen_string_literal: true

FactoryBot.define do
  factory :observation do
    planting
    author { planting.owner }
    kind { 'flowering' }
    observed_at { Time.zone.now }
    description { nil }
  end
end

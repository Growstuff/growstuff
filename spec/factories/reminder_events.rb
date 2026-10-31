# frozen_string_literal: true

FactoryBot.define do
  factory :reminder_event do
    member
    kind { 'planting_reminder' }
    event { 'sent' }
    created_at { Time.zone.now }
  end
end

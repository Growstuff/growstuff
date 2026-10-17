# frozen_string_literal: true

FactoryBot.define do
  factory :planting_history do
    planting
    garden
    started_on { 10.days.ago.to_date }
    ended_on { 3.days.ago.to_date }
  end
end

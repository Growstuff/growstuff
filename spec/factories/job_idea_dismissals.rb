# frozen_string_literal: true

FactoryBot.define do
  factory :job_idea_dismissal do
    member
    sequence(:key) { |n| "template:#{n}:1" }
    hidden_until { 1.week.from_now }
  end
end

# frozen_string_literal: true

# Read about factories at https://github.com/thoughtbot/factory_bot

FactoryBot.define do
  factory :plant_part do
    name { "#{Faker::Book.title}_#{rand(100..999)}" }
  end
end

# frozen_string_literal: true

# Read about factories at https://github.com/thoughtbot/factory_bot

FactoryBot.define do
  factory :plant_part do
    name { "#{Faker::Games::Pokemon.name} #{Faker::Number.number(digits: 10)}" }
  end
end

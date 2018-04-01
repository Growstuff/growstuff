# Read about factories at https://github.com/thoughtbot/factory_bot

FactoryBot.define do
  factory :plant_part do
    name { Faker::Book.unique.title }
  end
end

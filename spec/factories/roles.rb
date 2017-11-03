# Read about factories at https://github.com/thoughtbot/factory_bot

FactoryBot.define do
  factory :role do
    name "Moderator"
    description "These people moderate the forums"
    initialize_with { Role.find_or_create_by(name: name) }

    factory :admin do
      name "admin"
    end

    factory :crop_wrangler do
      name "Crop Wrangler"
      description "they wrangle crops"
    end
  end
end

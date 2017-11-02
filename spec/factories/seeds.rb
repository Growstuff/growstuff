# Read about factories at https://github.com/thoughtbot/factory_bot

FactoryBot.define do
  factory :seed do
    owner
    crop
    description "MyText"
    quantity 1
    plant_before "2013-07-15"
    tradable_to 'nowhere'
    organic 'unknown'
    gmo 'unknown'
    heirloom 'unknown'
    days_until_maturity_min nil
    days_until_maturity_max nil

    factory :tradable_seed do
      tradable_to "locally"
    end

    factory :untradable_seed do
      tradable_to "nowhere"
    end
  end
end

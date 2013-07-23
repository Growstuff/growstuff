# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :seed do
    owner
    crop
    description "MyText"
    quantity 1
    plant_before "2013-07-15"
    tradable_to 'nowhere'

    factory :tradable_seed do
      tradable_to "locally"
    end

    factory :untradable_seed do
      tradable_to "nowhere"
    end
  end
end

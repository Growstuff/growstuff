# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :seed do
    owner
    crop
    description "MyText"
    quantity 1
    plant_before "2013-07-15"

    factory :tradable_seed do
      tradable true
      tradable_to "locally"
    end
  end
end

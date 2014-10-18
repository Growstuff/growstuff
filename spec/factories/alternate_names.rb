# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :alternate_name do
    name "alternate name"
    crop
    creator

    factory :alternate_eggplant do
      association :crop, factory: :eggplant
      name "aubergine"
    end
  end
end

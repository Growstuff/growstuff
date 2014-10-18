# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :alternate_name do
    association :crop, factory: :crop
    name "alternate name"
    creator

    factory :alternate_tomato do
      association :crop, factory: :tomato
      name "alternative tomato"
    end
  end
end

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :harvest do
    crop
    plant_part
    owner
    harvested_at "2013-09-17"
    quantity "3"
    unit "individual"
    weight_quantity 6
    weight_unit "kg"
    description "A lovely harvest"
  end

  trait :long_description do
    description "This is a very long description that is so very long that it will need to be cut off"
  end

  trait :no_description do
    description ""
  end
end

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :harvest do
    crop
    owner
    harvested_at "2013-09-17"
    quantity "9.99"
    units "kg"
    notes "A lovely harvest"
  end
end

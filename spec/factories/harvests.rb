# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :harvest do
    crop_id 1
    owner_id 1
    harvested_at "2013-09-17"
    quantity "9.99"
    units "MyString"
    notes "MyText"
  end
end

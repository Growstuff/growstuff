# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :authentication do
    member_id 1
    provider "MyString"
    uid "MyString"
    secret "MyString"
  end
end

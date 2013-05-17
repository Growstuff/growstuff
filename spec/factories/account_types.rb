# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :account_type do
    name "MyString"
    is_paid false
    is_permanent_paid false
  end
end

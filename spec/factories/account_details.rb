# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :account_detail do
    member_id 1
    account_type "MyString"
    paid_until "2013-05-17 11:59:20"
  end
end

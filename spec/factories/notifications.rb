# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :notification do
    sender
    recipient
    subject "MyString"
    body "MyText"
    read false
    notification_type 1
    post
  end
end

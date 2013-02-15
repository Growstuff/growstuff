# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :notification do
    sender
    recipient
    subject "MyString"
    body "MyText"
    read false
    post
  end
end

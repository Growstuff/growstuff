# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :notification do
    from_id 1
    to_id 1
    subject "MyString"
    body "MyText"
    read false
    notification_type 1
    post_id 1
  end
end

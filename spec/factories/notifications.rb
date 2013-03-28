# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :notification do
    sender
    recipient
    subject "MyString"
    body "MyText"
    read false
    post

    factory :no_email_notification do
      recipient { FactoryGirl.create(:no_email_notifications_member) }
    end
  end
end

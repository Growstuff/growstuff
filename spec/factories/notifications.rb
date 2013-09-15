# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :notification, aliases: [:message] do
    sender
    recipient
    subject "MyString"
    body "MyText"
    read false
    post
    in_reply_to nil

    factory :no_email_notification do
      recipient { FactoryGirl.create(:no_email_notifications_member) }
    end
  end
end

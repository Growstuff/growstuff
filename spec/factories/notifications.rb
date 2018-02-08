# Read about factories at https://github.com/thoughtbot/factory_bot

FactoryBot.define do
  factory :notification, aliases: [:message] do
    sender
    recipient
    subject "MyString"
    body "MyText"
    read false
    post

    factory :no_email_notification do
      recipient { FactoryBot.create(:no_email_notifications_member) }
    end
  end
end

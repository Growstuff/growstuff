FactoryGirl.define do

  factory :user do
    username "user1"
    password "password1"
    email "user1@example.com"
    tos_agreement true

    factory :confirmed_user do
      confirmed_at Time.now()
    end

  end

end

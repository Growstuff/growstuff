# Read about factories at https://github.com/thoughtbot/factory_bot

FactoryBot.define do
  factory :order do
    member
    factory :completed_order do
      completed_at '2013-05-08 01:01:01'
    end

    factory :referred_order do
      referral_code 'CAMPAIGN1'
    end
  end
end

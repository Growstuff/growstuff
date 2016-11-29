# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :account_type do
    name "Free"
    is_paid false
    is_permanent_paid false

    factory :paid_account_type do
      name "Paid"
      is_paid true
      is_permanent_paid false
    end

    factory :permanent_paid_account_type do
      name "Permanent paid"
      is_paid true
      is_permanent_paid true
    end

    factory :staff_account_type do
      name "Staff"
      is_paid true
      is_permanent_paid true
    end
  end
end

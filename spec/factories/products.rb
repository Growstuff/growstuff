# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :product do
    name "annual subscription"
    description "paid membership, renewing yearly, *hurrah*"
    min_price "999"
    account_type
    paid_months 12
  end
end

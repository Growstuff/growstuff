# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :product do
    name "annual subscription"
    description "paid membership, renewing yearly, *hurrah*"
    min_price "999"
    account_type
    paid_months 12

    factory :product_with_recommended_price do
      recommended_price "1200"
    end
  end
end

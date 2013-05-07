# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :product do
    name "annual subscription"
    description "paid membership, renewing yearly"
    min_price "9.99"
  end
end

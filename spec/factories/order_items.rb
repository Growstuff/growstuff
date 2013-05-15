# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :order_item do
    order
    product
    price "999"
    quantity 1
  end
end

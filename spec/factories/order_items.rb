# Read about factories at https://github.com/thoughtbot/factory_bot

FactoryBot.define do
  factory :order_item do
    order
    product
    price "999"
    quantity 42
  end
end

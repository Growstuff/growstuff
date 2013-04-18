# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :authentication do
    member
    provider 'twitter'
    uid 'foo'
    secret 'bar'
    name 'baz'
  end
end

# Read about factories at https://github.com/thoughtbot/factory_bot

FactoryBot.define do
  factory :authentication do
    member
    provider 'twitter'
    uid 'foo'
    secret 'bar'
    name 'baz'

    factory :flickr_authentication do
      provider 'flickr'
      uid 'blah@blah'
    end
  end
end

# frozen_string_literal: true

# Read about factories at https://github.com/thoughtbot/factory_bot

FactoryBot.define do
  factory :authentication do
    member
    provider { 'flickr' }
    uid { 'foo' }
    secret { 'bar' }
    name { 'baz' }

    factory :mastodon_authentication do
      provider { 'mastodon' }
      uid { '111@mastodon.social' }
      name { '@alice@mastodon.social' }
      secret { nil }
    end

    factory :flickr_authentication do
      provider { 'flickr' }
      uid { 'blah@blah' }
    end
  end
end

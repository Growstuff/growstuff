# frozen_string_literal: true

FactoryBot.define do
  factory :stall_planting do
    stall
    planting { association :planting, owner: stall.member, strategy: :create }
    recipient_kind { 'email' }
    recipient { 'neighbour@example.com' }
    given_away_at { Time.zone.local(2026, 11, 14, 12) }

    trait :mastodon do
      recipient_kind { 'mastodon' }
      recipient { '@alice@mastodon.social' }
    end

    trait :bluesky do
      recipient_kind { 'bluesky' }
      recipient { 'alice.bsky.social' }
    end
  end
end

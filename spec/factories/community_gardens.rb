# frozen_string_literal: true

FactoryBot.define do
  factory :community_garden do
    sequence(:title) { |n| "Community Garden #{n}" }
    sequence(:osm_id) { |n| "node/#{n}" }
    website { 'https://example.org' }
    coordinates { '-37.8136, 144.9631' }
    wikidata_id { 'Q12345' }
    description { 'A community garden' }
    email { 'garden@example.org' }
  end
end

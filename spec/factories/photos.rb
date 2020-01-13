# frozen_string_literal: true

# Read about factories at https://github.com/thoughtbot/factory_bot

FactoryBot.define do
  factory :photo do
    owner
    source { 'flickr' }
    source_id { 1 }
    title { Faker::Movies::HarryPotter.quote }
    license_name { "CC-BY" }
    license_url { "http://example.com/license.html" }
    thumbnail_url { "http://example.com/#{Faker::File.file_name}.jpg" }
    fullsize_url { "http://example.com/#{Faker::File.file_name}.jpg" }
    link_url { Faker::Internet.url }

    factory :unlicensed_photo do
      license_name { "All rights reserved" }
      license_url { nil }
    end

    trait :reindex do
      after(:create) do |photo, _evaluator|
        photo.reindex(refresh: true)
      end
    end
  end
end

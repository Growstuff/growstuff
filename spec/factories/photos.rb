# Read about factories at https://github.com/thoughtbot/factory_bot

FactoryBot.define do
  factory :photo do
    owner
    flickr_photo_id 1
    title { Faker::HarryPotter.quote }
    license_name "CC-BY"
    license_url "http://example.com/license.html"
    thumbnail_url { "http://example.com/#{Faker::File.file_name}.jpg" }
    fullsize_url { "http://example.com/#{Faker::File.file_name}.jpg" }
    link_url { Faker::Internet.url }

    factory :unlicensed_photo do
      license_name "All rights reserved"
      license_url ""
    end
  end
end

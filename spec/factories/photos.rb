# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :photo do
    owner
    flickr_photo_id 1
    title "Still life with chillies"
    license_name "CC-BY"
    license_url "http://example.com/license.html"
    thumbnail_url "http://example.com/thumb.jpg"
    fullsize_url "http://example.com/full.jpg"
    link_url "http://example.com/"

    factory :unlicensed_photo do
      license_name "All rights reserved"
      license_url ""
    end
  end
end

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :photo do
    owner_id 1
    flickr_photo_id 1
    thumbnail_url "MyString"
    fullsize_url "MyString"
  end
end

# frozen_string_literal: true

FactoryBot.define do
  factory :member, aliases: %i(author owner sender recipient creator) do
    login_name { (0...8).map { rand(65..90).chr }.join }
    password { 'password1' }
    email { Faker::Internet.unique.email }
    tos_agreement { true }
    confirmed_at { Time.zone.now }
    show_email { false }
    bio { 'I love seeds' }
    preferred_avatar_uri { 'https://secure.gravatar.com/avatar/d021434aac03a7f7c7c0de60d07dad1c?size=150&default=identicon' }

    # cropbot is needed for certain tests, eg. Crop.create_from_csv
    factory :cropbot do
      login_name { 'cropbot' }
    end

    factory :no_tos_member do
      tos_agreement { false }
    end

    factory :newsletter_recipient_member do
      newsletter { true }
    end

    factory :no_bio_member do
      bio { nil }
    end

    factory :unconfirmed_member do
      confirmed_at { nil }
    end

    # this member has very loose privacy settings
    factory :public_member do
      login_name { 'NothingToHide' }
      show_email { true }
    end

    factory :london_member do
      sequence(:login_name) { |n| "JohnH#{n}" } # for the astronomer who figured out longitude
      location { 'Greenwich, UK' }
      # including lat/long explicitly because geocoder doesn't work with FactoryBot
      latitude { 51.483 }
      longitude { 0.004 }
    end

    factory :edinburgh_member do
      location { 'Edinburgh' }
      latitude { 55.953252 }
      longitude { -3.188267 }
    end

    factory :south_pole_member do
      sequence(:login_name) { |n| "ScottRF#{n}" }
      location { 'Amundsen-Scott Base, Antarctica' }
      latitude { -90 }
      longitude { 0 }
    end

    factory :interesting_member do
      sequence(:login_name) { |n| "ScottRF#{n}" }
      location { 'Edinburgh' }
      latitude { Faker::Address.latitude }
      longitude { Faker::Address.longitude }
      after(:create) do |member|
        create(:planting, owner: member, garden: member.gardens.first)
      end
    end

    factory :admin_member do
      roles { [FactoryBot.create(:admin)] }
    end

    factory :crop_wrangling_member do
      roles { [FactoryBot.create(:crop_wrangler)] }
      sequence(:login_name) { |n| "wrangler#{n}" }
    end

    factory :invalid_member_shortname do
      login_name { 'a' }
    end

    factory :invalid_member_longname do
      login_name { 'MarmadukeBlundellHollinsheadBlundellTolemachePlantagenetWhistlebinkie3rdDukeofMarmoset' }
    end

    factory :invalid_member_spaces do
      login_name { "a b" }
    end

    factory :invalid_member_badchars do
      login_name { 'aa%$' }
    end

    factory :invalid_member_badname do
      login_name { 'admin' }
    end

    factory :valid_member_alphanumeric do
      login_name { 'abc123' }
    end

    factory :valid_member_uppercase do
      login_name { 'ABC123' }
    end

    factory :valid_member_underscore do
      login_name { 'abc_123' }
    end

    factory :no_email_notifications_member do
      send_notification_email { false }
    end
  end
end

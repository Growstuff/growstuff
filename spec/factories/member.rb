FactoryGirl.define do
  sequence(:email) { |n| "member#{n}@example.com" }
  sequence(:login_name) { |n| "member#{n}" }

  factory :member, aliases: [:author, :owner, :sender, :recipient] do
    login_name { generate(:login_name) }
    password 'password1'
    email { generate(:email) }
    tos_agreement true
    confirmed_at Time.now
    show_email false
    about_me "I like to garden all day long"

    factory :no_tos_member do
      tos_agreement false
    end

    factory :unconfirmed_member do
      confirmed_at nil
    end

    # this member has very loose privacy settings
    factory :public_member do
      login_name 'NothingToHide'
      show_email true
    end

    factory :geolocated_member do
      login_name 'JohnH' # for the astronomer who figured out longitude
      location 'Greenwich, UK'
      # including lat/long explicitly because geocoder doesn't work with FG
      latitude 51.483
      longitude 0.004
    end

    factory :admin_member do
      roles { [ FactoryGirl.create(:admin) ] }
    end

    factory :crop_wrangling_member do
      roles { [ FactoryGirl.create(:crop_wrangler) ] }
    end

    factory :invalid_member_shortname do
      login_name 'a'
    end

    factory :invalid_member_longname do
      login_name 'MarmadukeBlundellHollinsheadBlundellTolemachePlantagenetWhistlebinkie3rdDukeofMarmoset'
    end

    factory :invalid_member_spaces do
      login_name "a b"
    end

    factory :invalid_member_badchars do
      login_name 'aa%$'
    end

    factory :invalid_member_badname do
      login_name 'admin'
    end

    factory :valid_member_alphanumeric do
      login_name 'abc123'
    end

    factory :valid_member_uppercase do
      login_name 'ABC123'
    end

    factory :valid_member_underscore do
      login_name 'abc_123'
    end

  end

end

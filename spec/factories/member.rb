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

    factory :no_tos_member do
      tos_agreement false
    end

    factory :unconfirmed_member do
      confirmed_at nil
    end

    factory :long_name_member do
      login_name 'Marmaduke Blundell-Hollinshead-Blundell-Tolemache-Plantagenet-Whistlebinkie, 3rd Duke of Marmoset'
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

  end

end

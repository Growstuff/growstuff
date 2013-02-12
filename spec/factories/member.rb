FactoryGirl.define do
  sequence(:email) { |n| "member#{n}@example.com" }

  factory :member, aliases: [:author, :owner] do
    login_name 'member1'
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
      location 'Greenwich, UK'
      # including lat/long explicitly because geocoder doesn't work with FG
      latitude 51.483
      longitude 0.004
    end

  end

end

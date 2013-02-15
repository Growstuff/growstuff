FactoryGirl.define do
  sequence(:email) { |n| "member#{n}@example.com" }

  factory :member, aliases: [:author, :owner, :sender, :recipient] do
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

  end

end

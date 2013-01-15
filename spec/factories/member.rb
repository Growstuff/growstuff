FactoryGirl.define do

  factory :member, aliases: [:author, :owner] do
    login_name 'member1'
    password 'password1'
    email 'member1@example.com'
    tos_agreement true
    confirmed_at Time.now

    factory :no_tos_member do
      tos_agreement false
      email 'notos@example.com'
    end

    factory :unconfirmed_member do
      confirmed_at nil
      email 'confirmed@example.com'
    end

    factory :long_name_member do
      login_name 'Marmaduke Blundell-Hollinshead-Blundell-Tolemache-Plantagenet-Whistlebinkie, 3rd Duke of Marmoset'
      email 'marmaduke@example.com'
    end

  end

end

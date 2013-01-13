FactoryGirl.define do

  factory :user do
    username 'user1'
    password 'password1'
    email 'user1@example.com'
    tos_agreement true

    factory :no_tos_user do
      tos_agreement false
      email 'notos@example.com'
    end

    factory :confirmed_user do
      confirmed_at Time.now()
      email 'confirmed@example.com'
    end

    factory :long_name_user do
      username 'Marmaduke Blundell-Hollinshead-Blundell-Tolemache-Plantagenet-Whistlebinkie, 3rd Duke of Marmoset'
      email 'marmaduke@example.com'
    end

  end

end

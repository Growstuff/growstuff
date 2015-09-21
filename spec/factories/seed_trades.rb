FactoryGirl.define do
  factory :seed_trade do
    message "MyText"
    address "MyText"
    requested_date "2015-09-12 17:57:45"
    created_at "2015-09-12 17:57:45"
    accepted_date nil
    declined_date nil
    sent_date nil
    received_date nil
    seed
    requester { FactoryGirl.build(:member) }

    factory :accepted_seed_trade do
      accepted_date "2015-09-12 17:57:45"
    end

    factory :declined_seed_trade do
      declined_date "2015-09-12 17:57:45"
    end

    factory :sent_seed_trade do
      accepted_date "2015-09-12 17:57:45"
      sent_date "2015-09-12 17:57:45"
    end

    factory :received_seed_trade do
      accepted_date "2015-09-12 17:57:45"
      sent_date "2015-09-12 17:57:45"
      received_date "2015-09-12 17:57:45"
    end

  end
end

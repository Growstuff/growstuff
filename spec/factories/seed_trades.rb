FactoryGirl.define do
  factory :seed_trade do
    message "MyText"
    address "MyText"
    requested_date "2015-09-12 17:57:45"
    accepted_date "2015-09-12 17:57:45"
    declined_date "2015-09-12 17:57:45"
    sent_date "2015-09-12 17:57:45"
    received_date "2015-09-12 17:57:45"
    seed
    requester { FactoryGirl.build(:member) }
  end
end

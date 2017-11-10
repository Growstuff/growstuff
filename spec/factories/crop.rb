FactoryBot.define do
  factory :crop do
    name "magic bean"
    en_wikipedia_url "http://en.wikipedia.org/wiki/Magic_bean"
    approval_status "approved"
    creator

    factory :annual_crop, parent: :crop do
      perennial false
    end
    factory :perennial_crop, parent: :crop do
      perennial true
    end

    factory :tomato do
      name "tomato"
      en_wikipedia_url "http://en.wikipedia.org/wiki/Tomato"
    end

    factory :maize do
      name "maize"
      en_wikipedia_url "http://en.wikipedia.org/wiki/Maize"
    end

    factory :chard do
      name "chard"
    end

    factory :walnut do
      name "walnut"
    end

    factory :apple do
      name "apple"
    end

    factory :pear do
      name "pear"
    end

    # for testing varieties
    factory :roma do
      name "roma tomato"
    end

    factory :popcorn do
      name "popcorn"
    end

    factory :eggplant do
      name "eggplant"
    end

    # This should have a name that is alphabetically earlier than :uppercase
    # crop to ensure that the ordering tests work.
    factory :lowercasecrop do
      name "ffrench bean"
    end

    factory :uppercasecrop do
      name "Swiss chard"
    end

    factory :autoloaded_crop do
      creator "cropbot"
    end

    # for testing crop request
    factory :crop_request do
      name "Ultra berry"
      en_wikipedia_url ""
      approval_status "pending"
      association :requester, factory: :member
      request_notes "Please approve this even though it's fake."
    end

    factory :rejected_crop do
      name "Fail bean"
      approval_status "rejected"
      reason_for_rejection "Totally fake"
    end
  end
end

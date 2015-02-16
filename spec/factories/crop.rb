FactoryGirl.define do

  factory :crop do
    name "magic bean"
    en_wikipedia_url "http://en.wikipedia.org/wiki/Magic_bean"
    creator

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

  end

end

FactoryGirl.define do

  factory :crop do
    name "Magic bean"
    en_wikipedia_url "http://en.wikipedia.org/wiki/Magic_bean"
    creator

    factory :tomato do
      name "Tomato"
      en_wikipedia_url "http://en.wikipedia.org/wiki/Tomato"
    end

    factory :maize do
      name "Maize"
      en_wikipedia_url "http://en.wikipedia.org/wiki/Maize"
    end

    factory :chard do
      name "Chard"
    end

    factory :walnut do
      name "Walnut"
    end

    factory :apple do
      name "Apple"
    end

    factory :pear do
      name "Pear"
    end

    # for testing varieties
    factory :roma do
      name "Roma tomato"
    end

    factory :popcorn do
      name "popcorn"
    end


    # This should have a name that is alphabetically earlier than :uppercase
    # crop to ensure that the ordering tests work.
    factory :lowercasecrop do
      name "ffrench bean"
    end

    factory :uppercasecrop do
      name "Swiss chard"
    end

  end

end

FactoryGirl.define do

  factory :crop do
    system_name "Magic bean"
    en_wikipedia_url "http://en.wikipedia.org/wiki/Magic_bean"

    factory :tomato do
      system_name "Tomato"
      en_wikipedia_url "http://en.wikipedia.org/wiki/Tomato"
    end

    factory :maize do
      system_name "Maize"
      en_wikipedia_url "http://en.wikipedia.org/wiki/Maize"
    end

    factory :chard do
      system_name "Chard"
    end

    factory :walnut do
      system_name "Walnut"
    end

    factory :apple do
      system_name "Apple"
    end

    factory :pear do
      system_name "Pear"
    end

    # for testing varieties
    factory :roma do
      system_name "Roma tomato"
    end

    factory :popcorn do
      system_name "popcorn"
    end


    # This should have a name that is alphabetically earlier than :uppercase
    # crop to ensure that the ordering tests work.
    factory :lowercasecrop do
      system_name "ffrench bean"
    end

    factory :uppercasecrop do
      system_name "Swiss chard"
    end

  end

end

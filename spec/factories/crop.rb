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

    factory :lowercasecrop do
      system_name "ffrench bean"
    end

  end

end

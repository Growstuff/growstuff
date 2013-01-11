FactoryGirl.define do

  factory :crop do

    factory :tomato do
      system_name "Tomato"
      en_wikipedia_url "http://en.wikipedia.org/wiki/Tomato"
    end

    factory :maize do
      system_name "Maize"
      en_wikipedia_url "http://en.wikipedia.org/wiki/Maize"
    end

  end

end

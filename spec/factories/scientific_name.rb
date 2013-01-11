FactoryGirl.define do
  factory :scientific_name do
    factory :zea_mays do
      association :crop, factory: :maize
      scientific_name "Zea mays"
    end
    factory :solanum_lycopersicum do
      association :crop, factory: :tomato
      scientific_name "Solanum lycopersicum"
    end
  end
end

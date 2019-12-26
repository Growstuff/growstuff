# frozen_string_literal: true

FactoryBot.define do
  factory :scientific_name do
    association :crop, factory: :crop
    name { "Beanus Magicus" }
    creator

    factory :zea_mays do
      association :crop, factory: :maize
      name { "Zea mays" }
    end

    factory :solanum_lycopersicum do
      association :crop, factory: :tomato
      name { "Solanum lycopersicum" }
    end
  end
end

# Read about factories at https://github.com/thoughtbot/factory_bot

FactoryBot.define do
  factory :harvest do
    crop { planting.present? ? planting.crop : FactoryBot.create(:crop) }
    plant_part
    planting nil
    owner { planting.present? ? planting.owner : FactoryBot.create(:member) }
    harvested_at { Time.zone.local(2015, 9, 17) }
    quantity "3"
    unit "individual"
    weight_quantity 6
    weight_unit "kg"
    description "A lovely harvest"

    factory :harvest_with_planting do
      planting
    end
  end

  trait :long_description do
    description "This is a very long description that is so very long that it will need to be cut off"
  end

  trait :no_description do
    description ""
  end
end

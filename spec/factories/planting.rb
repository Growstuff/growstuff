FactoryGirl.define do
  factory :planting do
    garden
    crop
    planted_at Date.today
    quantity 33
    description "This is a *really* good plant."
    planted_from 'seed'

    factory :sunny_planting do
      sunniness 'sun'
    end

    factory :semi_shady_planting do
      sunniness 'semi-shade'
    end

    factory :shady_planting do
      sunniness 'shade'
    end
  end
end

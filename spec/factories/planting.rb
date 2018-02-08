FactoryBot.define do
  factory :planting do
    owner
    garden { FactoryBot.create :garden, owner: owner }
    crop
    planted_at { Time.zone.local(2014, 7, 30) }
    quantity 33
    description "This is a *really* good plant."

    factory :seed_planting do
      planted_from 'seed'
    end

    factory :seedling_planting do
      planted_from 'seedling'
    end

    factory :cutting_planting do
      planted_from 'cutting'
    end

    factory :sunny_planting do
      sunniness 'sun'
    end

    factory :semi_shady_planting do
      sunniness 'semi-shade'
    end

    factory :shady_planting do
      sunniness 'shade'
    end

    factory :finished_planting do
      finished true
      planted_at { Time.zone.local(2014, 7, 30) }
      finished_at { Time.zone.local(2014, 8, 30) }
    end
  end
end

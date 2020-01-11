# frozen_string_literal: true

FactoryBot.define do
  factory :planting do
    owner
    garden { FactoryBot.create :garden, owner: owner }
    crop
    planted_at { Time.zone.local(2014, 7, 30) }
    quantity { 33 }
    description { "This is a *really* good plant." }
    finished { false }
    finished_at { nil }

    factory :seed_planting do
      planted_from { 'seed' }
    end

    factory :seedling_planting do
      planted_from { 'seedling' }
    end

    factory :cutting_planting do
      planted_from { 'cutting' }
    end

    factory :sunny_planting do
      sunniness { 'sun' }
    end

    factory :semi_shady_planting do
      sunniness { 'semi-shade' }
    end

    factory :shady_planting do
      sunniness { 'shade' }
    end

    factory :finished_planting do
      finished { true }
      planted_at { Time.zone.local(2014, 7, 30) }
      finished_at { Time.zone.local(2014, 8, 30) }
    end

    factory :annual_planting do
      crop { FactoryBot.create :annual_crop }
    end

    factory :perennial_planting do
      crop { FactoryBot.create :perennial_crop }
    end

    factory :predicatable_planting do
      crop do
        crop = FactoryBot.create :annual_crop
        FactoryBot.create :planting, crop: crop, planted_at: 10.days.ago
        FactoryBot.create :planting, crop: crop, planted_at: 100.days.ago, finished_at: 50.days.ago
        FactoryBot.create :planting, crop: crop, planted_at: 100.days.ago, finished_at: 51.days.ago
        FactoryBot.create :planting, crop: crop, planted_at: 2.years.ago, finished_at: 50.days.ago
        FactoryBot.create :planting, crop: crop, planted_at: 150.days.ago, finished_at: 100.days.ago
        crop.update_lifespan_medians
        crop
      end
    end

    trait :with_photo do
      after(:create) do |planting, _evaluator|
        planting.photos << FactoryBot.create(:photo, owner_id: planting.owner_id)
        planting.save
      end
    end

    trait :reindex do
      after(:create) do |planting, _evaluator|
        planting.reindex(refresh: true)
      end
    end
  end
end

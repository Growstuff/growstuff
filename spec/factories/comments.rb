# frozen_string_literal: true

FactoryBot.define do
  factory :comment do
    association :author, factory: :member # Explicitly use :member factory for author
    sequence(:body) { |n| "OMG LOL #{n}" }

    # Default to associating with a post if no specific commentable is provided
    association :commentable, factory: :post

    trait :for_post do
      association :commentable, factory: :post
    end

    trait :for_photo do
      association :commentable, factory: :photo
    end

    trait :for_planting do
      association :commentable, factory: :planting
    end

    trait :for_harvest do
      association :commentable, factory: :harvest
    end

    trait :for_activity do
      association :commentable, factory: :activity
    end
  end
end

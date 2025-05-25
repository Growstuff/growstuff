# frozen_string_literal: true

FactoryBot.define do
  factory :post do
    association :author, factory: :member
    association :forum # Assuming posts belong to a forum
    sequence(:subject) { |n| "Test Post Subject #{n}" }
    sequence(:body) { |n| "This is the body of test post #{n}." }

    # Add traits if needed, e.g., for posts with photos, crops, etc.
    trait :with_photos do
      transient do
        photos_count { 1 }
      end
      after(:create) do |post, evaluator|
        create_list(:photo, evaluator.photos_count, owner: post.author, post_id: post.id) # Assuming Photo has post_id or similar
      end
    end

    trait :with_crops do
      transient do
        crops_count { 1 }
      end
      after(:create) do |post, evaluator|
        create_list(:crop, evaluator.crops_count, posts: [post]) # Assuming a has_and_belongs_to_many or has_many :through
      end
    end
  end
end

# Assuming a Forum model exists and has a factory
FactoryBot.define do
  factory :forum do
    sequence(:name) { |n| "Test Forum #{n}" }
    # Add other attributes for Forum as needed
  end
end

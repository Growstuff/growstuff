FactoryGirl.define do
  factory :planting do
    garden
    crop
    planted_at Time.now
    quantity 3
    description "This is a *really* good plant."
  end
end

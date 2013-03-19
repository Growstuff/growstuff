FactoryGirl.define do
  factory :planting do
    garden
    crop
    planted_at Time.now
    quantity 33
    description "This is a *really* good plant."
  end
end

FactoryGirl.define do
  factory :planting do
    garden
    crop
    planted_at Date.today
    quantity 33
    description "This is a *really* good plant."
    sunniness 'sun'
    planted_from 'seed'
  end
end

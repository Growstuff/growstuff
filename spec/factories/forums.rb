# Read about factories at https://github.com/thoughtbot/factory_bot

FactoryBot.define do
  factory :forum do
    name "Permaculture"
    description "*Everything* about permaculture!"
    owner
  end
end

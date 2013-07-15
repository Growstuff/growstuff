# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :seed do
    owner
    crop
    description "MyText"
    quantity 1
    use_by "2013-07-15"
  end
end

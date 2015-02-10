FactoryGirl.define do
  factory :like do
    member 
    association :likeable, :factory => "post"
  end

end

FactoryGirl.define do
  factory :garden do
    name 'Springfield Community Garden'
    description "This is a **totally** cool garden"
    owner
    active true
    area 23
    area_unit "acre"
    location "Greenwich, UK"

    factory :inactive_garden do
      active false
    end

    # the following are used for testing alphabetical ordering
    factory :garden_a do
      name 'A garden starting with A'
    end

    factory :garden_z do
      name 'Zzzz this garden makes me sleepy'
    end

    # the following are used to test the partial _area
    factory :garden_square_metre do 
      area_unit "square metre"
    end

    factory :garden_square_foot do 
      area_unit "square foot"
    end

    factory :garden_hectare do 
      area_unit "hectare"
    end

    factory :garden_acre do 
      area_unit "acre"
    end

    factory :garden_no_area do 
      area nil
    end

  end
end

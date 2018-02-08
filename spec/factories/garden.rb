FactoryBot.define do
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
  end
end

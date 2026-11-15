# frozen_string_literal: true

FactoryBot.define do
  factory :ecocrop_data do
    sequence(:ecoportcode) { |n| 10_000 + n }
    scientificname { 'Solanum lycopersicum' }
    tmin { 10 }
    topmn { 20 }
    topmx { 30 }
    gmin { 60 }
    gmax { 120 }
  end
end

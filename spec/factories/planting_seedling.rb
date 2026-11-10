# frozen_string_literal: true

FactoryBot.define do
  factory :planting_seedling do
    planting
    source { 'nursery' }
    supplier { 'Kings Plant Barn' }
  end
end

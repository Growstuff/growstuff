# frozen_string_literal: true

FactoryBot.define do
  factory :domesticated_animal do
    name { 'Henrietta' }
    species { 'Gallus gallus domesticus' }
    category { 'chicken' }
    owner
  end
end

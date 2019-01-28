# frozen_string_literal: true

FactoryBot.define do
  factory :like do
    member
    association :likeable, factory: "post"
  end
end

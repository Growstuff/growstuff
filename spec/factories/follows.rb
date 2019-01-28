# frozen_string_literal: true

FactoryBot.define do
  factory :follow do
    follower
    followed
  end
end

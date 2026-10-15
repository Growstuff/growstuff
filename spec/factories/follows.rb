# frozen_string_literal: true

FactoryBot.define do
  factory :follow do
    follower { association :member }
    followed { association :member }
  end
end

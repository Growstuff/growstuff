# frozen_string_literal: true

FactoryBot.define do
  factory :comment do
    post
    author
    sequence(:body) { |n| "OMG LOL #{n}" }
    # because our commenters are more polite than YouTube's
  end
end

# frozen_string_literal: true

FactoryBot.define do
  factory :stall_seed do
    stall { association :stall, :open, claim_area: 'anywhere' }
    seed { association :seed, owner: stall.member }
  end
end

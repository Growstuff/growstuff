# frozen_string_literal: true

FactoryBot.define do
  factory :crop_job_step do
    crop_job_template
    name { 'Stake or cage the plants' }
    offset_amount { 2 }
  end
end

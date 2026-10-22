# frozen_string_literal: true

FactoryBot.define do
  factory :crop_job_template do
    crop
    name { 'Tomato jobs' }
  end
end

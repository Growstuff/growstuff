# frozen_string_literal: true

# Read about factories at https://github.com/thoughtbot/factory_bot

FactoryBot.define do
  factory :plant_part do
    names = ["seed", "leaf", "bulb", "other", "tuber", "whole plant", "bark", "pod", "stem", "root", "fruit", "flower"]
    sequence(:name, names.length-1) { |n| names[n] }
  end
end

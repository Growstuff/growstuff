# frozen_string_literal: true

class AustralianFoodClassificationData < ApplicationRecord
  belongs_to :crop,
             foreign_key: :public_food_key,
             primary_key: :public_food_key,
             inverse_of:  :australian_food_classification_data
end

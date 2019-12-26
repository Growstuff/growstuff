# frozen_string_literal: true

class CropCompanion < ApplicationRecord
  belongs_to :crop_a, class_name: :Crop
  belongs_to :crop_b, class_name: :Crop
end

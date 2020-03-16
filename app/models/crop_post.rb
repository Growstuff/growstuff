# frozen_string_literal: true

class CropPost < ApplicationRecord
  belongs_to :crop
  belongs_to :post
end

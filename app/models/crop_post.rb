# frozen_string_literal: true

class CropPost < ApplicationRecord
  belongs_to :crop
  belongs_to :post

  attr_accessible :crop_id, :post_id
end

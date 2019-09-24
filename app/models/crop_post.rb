class CropPost < ApplicationRecord
  belongs_to :crop
  belongs_to :post
end
# frozen_string_literal: true

# A crop a member has said does not suit them. The home page leaves it out of
# its suggestions.
class CropDismissal < ApplicationRecord
  belongs_to :member
  belongs_to :crop

  validates :crop_id, uniqueness: { scope: :member_id }
end

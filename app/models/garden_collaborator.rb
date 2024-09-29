# frozen_string_literal: true

class GardenCollaborator < ApplicationRecord
  belongs_to :member
  belongs_to :garden
end

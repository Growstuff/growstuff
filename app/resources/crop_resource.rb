# frozen_string_literal: true

class CropResource < ApplicationResource
  self.model = Crop
  read_only
  secondary_endpoint '/crops/search', [:search]

  attribute :name, :string
  attribute :en_wikipedia_url, :string
  attribute :perennial, :boolean
  attribute :median_lifespan, :integer
  attribute :median_days_to_first_harvest, :integer
  attribute :median_days_to_last_harvest, :integer
  filter_only :approval_status, :string

  default_filter :approval_status do |scope|
    scope.where(approval_status: 'approved')
  end

  belongs_to :parent, resource: CropResource
  filter_only :parent_id, :integer
  has_many :plantings
  has_many :seeds
  has_many :harvests
  has_many :photos, foreign_key: :crop_id,
                    base_scope:  -> { Photo.joins(:photo_associations).select('photos.*, photo_associations.crop_id AS crop_id').distinct }
end

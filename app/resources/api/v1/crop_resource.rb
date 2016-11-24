class Api::V1::CropResource < JSONAPI::Resource
  attributes :name, :en_wikipedia_url, :seeds
  has_many :plantings
  has_many :harvests
  has_many :seeds
  has_one :parent
end

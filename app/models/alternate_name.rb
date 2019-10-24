class AlternateName < ApplicationRecord
  belongs_to :crop
  belongs_to :creator, class_name: 'Member', inverse_of: :created_alternate_names
  validates :name, presence: true
  validates :crop, presence: true

  after_commit :reindex if ENV["GROWSTUFF_ELASTICSEARCH"] == "true"

  delegate :reindex, to: :crop
end

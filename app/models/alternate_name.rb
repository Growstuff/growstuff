class AlternateName < ApplicationRecord
  after_commit { |an| an.crop.__elasticsearch__.index_document if an.crop && ENV['GROWSTUFF_ELASTICSEARCH'] == "true" }
  belongs_to :crop
  belongs_to :creator, class_name: 'Member', inverse_of: :created_alternate_names
  validates :name, presence: true
  validates :crop, presence: true
end

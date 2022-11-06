# frozen_string_literal: true

class AlternateName < ApplicationRecord
  belongs_to :crop
  belongs_to :creator, class_name: 'Member', inverse_of: :created_alternate_names
  validates :name, presence: true
  validates :crop, presence: true

  attr_accessible :name, :crop_id, :creator_id

  after_commit :reindex

  delegate :reindex, to: :crop
end

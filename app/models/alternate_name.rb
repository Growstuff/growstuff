# frozen_string_literal: true

class AlternateName < ApplicationRecord
  belongs_to :crop
  belongs_to :creator, class_name: 'Member', inverse_of: :created_alternate_names
  validates :name, presence: true
  validates :crop, presence: true

  after_commit :reindex

  delegate :reindex, to: :crop
end

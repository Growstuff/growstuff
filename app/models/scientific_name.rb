# frozen_string_literal: true

class ScientificName < ApplicationRecord
  belongs_to :crop
  belongs_to :creator, class_name: 'Member', inverse_of: :created_scientific_names
  validates :name, presence: true
  validates :crop, presence: true
  after_commit :reindex
  delegate :reindex, to: :crop

  def to_s
    name
  end
end

# frozen_string_literal: true

class AlternateName < ApplicationRecord
  # Only crop search reads it (see SearchCrops).
  self.ignored_columns += %w(normalised_name)

  belongs_to :crop, optional: true
  belongs_to :problem, optional: true
  belongs_to :creator, class_name: 'Member', optional: true, inverse_of: :created_alternate_names

  validates :name, presence: true
end

# frozen_string_literal: true

class ScientificName < ApplicationRecord
  # Only crop search reads it (see SearchCrops).
  self.ignored_columns += %w(normalised_name)

  belongs_to :crop, optional: true
  belongs_to :problem, optional: true
  belongs_to :creator, class_name: 'Member', optional: true, inverse_of: :created_scientific_names

  validates :name, presence: true

  alias_attribute :gbif_id, :gbif_key

  def to_s
    name
  end
end

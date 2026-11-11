# frozen_string_literal: true

class AlternateName < ApplicationRecord
  # Only crop search reads it (see SearchCrops).
  self.ignored_columns += %w(normalised_name)

  belongs_to :crop
  belongs_to :creator, class_name: 'Member', inverse_of: :created_alternate_names

  normalizes :language, with: ->(language) { language.match?(/\A[A-Za-z]{2}\z/) ? language.downcase : language }

  validates :name, presence: true
  validates :crop, presence: true
  validates :language, presence: true
end

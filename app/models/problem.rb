# frozen_string_literal: true

class Problem < ApplicationRecord
  PROBLEM_TYPES = %w(Disease Pest General).freeze

  has_many :scientific_names, as: :subject, dependent: :destroy
  has_many :alternate_names, as: :subject, dependent: :destroy

  accepts_nested_attributes_for :scientific_names, allow_destroy: true, reject_if: :all_blank
  accepts_nested_attributes_for :alternate_names, allow_destroy: true, reject_if: :all_blank

  validates :title, presence: true
  validates :problem_type, presence: true, inclusion: { in: PROBLEM_TYPES }

  def to_s
    title
  end
end

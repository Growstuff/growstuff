# frozen_string_literal: true

class AlternateName < ApplicationRecord
  # Only crop search reads it (see SearchCrops).
  self.ignored_columns += %w(normalised_name)

  belongs_to :subject, polymorphic: true, optional: true
  belongs_to :crop, optional: true
  belongs_to :problem, optional: true
  belongs_to :creator, class_name: 'Member', inverse_of: :created_alternate_names

  before_validation :sync_subject_and_crop

  validates :name, presence: true

  private

  def sync_subject_and_crop
    if crop.present? && subject.nil?
      self.subject = crop
    elsif subject.is_a?(Crop)
      self.crop = subject
    end
  end
end

# frozen_string_literal: true

class EcocropData < ApplicationRecord
  validates :ecoportcode, presence: true, uniqueness: true
  validates :scientificname, presence: true

  def self.by_scientific_name(name)
    return nil if name.blank?

    cleaned = name.to_s.strip
    where('lower(scientificname) = lower(?)', cleaned).first
  end
end

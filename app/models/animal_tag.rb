# frozen_string_literal: true

class AnimalTag < ApplicationRecord
  belongs_to :domesticated_animal
  belongs_to :taggable, polymorphic: true

  validates :domesticated_animal_id, uniqueness: { scope: %i(taggable_type taggable_id) }
end

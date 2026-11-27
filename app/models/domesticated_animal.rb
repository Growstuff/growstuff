# frozen_string_literal: true

class DomesticatedAnimal < ApplicationRecord
  include PhotoCapable
  include Jobbable

  belongs_to :owner, class_name: 'Member', inverse_of: :domesticated_animals
  has_many :animal_tags, dependent: :delete_all
  has_many :posts, through: :animal_tags, source: :taggable, source_type: 'Post'

  default_scope { joins(:owner).merge(Member.kept) }

  enum :category, %w(dog cat chicken turkey guinea_pig).index_with(&:itself), validate: true
  enum :biological_sex, %w(female male intersex unknown).index_with(&:itself), prefix: true, validate: { allow_nil: true }

  normalizes :biological_sex, with: ->(value) { value.presence }
  validates :name, :species, presence: true
  validates :name, :species, :description, length: { maximum: 255 }
  validate :death_not_before_birth

  def to_s
    name
  end

  private

  def death_not_before_birth
    return unless date_of_birth && date_of_death && date_of_death < date_of_birth

    errors.add(:date_of_death, :before_birth)
  end
end

# frozen_string_literal: true

class DomesticatedAnimal < ApplicationRecord
  include PhotoCapable
  include Jobbable

  belongs_to :owner, class_name: 'Member', inverse_of: :domesticated_animals
  has_many :animal_tags, dependent: :delete_all
  has_many :posts, through: :animal_tags, source: :taggable, source_type: 'Post'

  default_scope { joins(:owner).merge(Member.kept) }

  enum :category, %w(
    dog cat chicken turkey duck goose guinea_pig sheep horse goat pig
    rabbit donkey alpaca llama quail guinea_fowl pigeon ferret other
  ).index_with(&:itself), validate: true
  enum :biological_sex, %w(female male intersex unknown).index_with(&:itself), prefix: true, validate: { allow_nil: true }
  enum :alignment, %w(
    lawful_good neutral_good chaotic_good
    lawful_neutral true_neutral chaotic_neutral
    lawful_evil neutral_evil chaotic_evil
  ).index_with(&:itself), prefix: true, validate: { allow_nil: true }

  normalizes :biological_sex, with: ->(value) { value.presence }
  normalizes :alignment, with: ->(value) { value.presence }
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

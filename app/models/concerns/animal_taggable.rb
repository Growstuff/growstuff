# frozen_string_literal: true

# Animal mentions use IDs rather than names, which are not unique. Shared by
# posts and comments; the same markdown links work in other descriptions too.
module AnimalTaggable
  extend ActiveSupport::Concern

  included do
    has_many :animal_tags, as: :taggable, dependent: :delete_all
    has_many :domesticated_animals, through: :animal_tags
    after_save :update_animal_tags, if: :saved_change_to_body?
  end

  private

  def update_animal_tags
    ids = body.to_s.scan(Haml::Filters::GrowstuffMarkdown::ANIMAL_REGEX).pluck(1).uniq
    self.domesticated_animals = DomesticatedAnimal.where(id: ids)
  end
end

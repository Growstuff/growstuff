require_relative '../../constants/photo_models.rb'
module PhotoCapable
  extend ActiveSupport::Concern

  included do
    has_and_belongs_to_many :photos # rubocop:disable Rails/HasAndBelongsToMany

    before_destroy :remove_from_list
    scope :has_photos, -> { includes(:photos).where.not(photos: { id: nil }) }
  end

  def remove_from_list
    photolist = photos.to_a # save a temp copy of the photo list
    photos.clear # clear relationship b/w object and photo

    photolist.each(&:destroy_if_unused)
  end
end

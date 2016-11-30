module PhotoCapable
  extend ActiveSupport::Concern

  included do
    has_and_belongs_to_many :photos

    before_destroy :remove_from_list
  end

  def remove_from_list
    photolist = photos.to_a # save a temp copy of the photo list
    photos.clear # clear relationship b/w object and photo

    photolist.each(&:destroy_if_unused)
  end
end

module PhotoCapable
  extend ActiveSupport::Concern

  included do
    has_and_belongs_to_many :photos

    before_destroy :remove_from_list
  end

  def remove_from_list
    photolist = self.photos.to_a # save a temp copy of the photo list
    self.photos.clear # clear relationship b/w object and photo

    photolist.each do |photo|
      photo.destroy_if_unused
    end
  end
end

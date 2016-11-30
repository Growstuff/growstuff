class Photo < ActiveRecord::Base
  ON_MODELS = %w(plantings harvests gardens).freeze
  belongs_to :owner, class_name: 'Member'

  ON_MODELS.each do |relation|
    has_and_belongs_to_many relation.to_sym
  end

  before_destroy { relationships.clear }

  default_scope { order("created_at desc") }

  def relationships
    associations = []
    ON_MODELS.each do |association_name, _reflection|
      associations << self.send(association_name.to_s).to_a
    end
    associations.flatten!
  end

  # remove photos that aren't used by anything
  def destroy_if_unused
    self.destroy unless relationships.size > 0
  end

  # This is split into a side-effect free method and a side-effecting method
  # for easier stubbing and testing.
  def flickr_metadata
    flickr = owner.flickr
    info = flickr.photos.getInfo(photo_id: flickr_photo_id)
    licenses = flickr.photos.licenses.getInfo()
    license = licenses.find { |l| l.id == info.license }
    return {
      title: info.title || "Untitled",
      license_name: license.name,
      license_url: license.url,
      thumbnail_url: FlickRaw.url_q(info),
      fullsize_url: FlickRaw.url_z(info),
      link_url: FlickRaw.url_photopage(info)
    }
  end

  def set_flickr_metadata
    self.update_attributes(flickr_metadata)
  end
end

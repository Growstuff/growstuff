class Photo < ActiveRecord::Base
  belongs_to :owner, class_name: 'Member'

  has_and_belongs_to_many :plantings
  has_and_belongs_to_many :harvests
  has_and_belongs_to_many :gardens
  before_destroy do |photo|
    photo.plantings.clear
    photo.harvests.clear
    photo.gardens.clear
  end

  default_scope { order("created_at desc") }

  # remove photos that aren't used by anything
  def destroy_if_unused
    unless plantings.size > 0 or harvests.size > 0 or gardens.size > 0
      self.destroy
    end
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

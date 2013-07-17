class Photo < ActiveRecord::Base
  attr_accessible :flickr_photo_id, :owner_id, :title, :license_name,
    :license_url, :thumbnail_url, :fullsize_url, :link_url
  belongs_to :owner, :class_name => 'Member'

  has_and_belongs_to_many :plantings
  before_destroy {|photo| photo.plantings.clear}

  default_scope order("created_at desc")

  # This is split into a side-effect free method and a side-effecting method
  # for easier stubbing and testing.
  def flickr_metadata
    flickr = owner.flickr
    info = flickr.photos.getInfo(:photo_id => flickr_photo_id)
    licenses = flickr.photos.licenses.getInfo()
    license = licenses.find { |l| l.id == info.license }
    return {
      :title => info.title || "Untitled",
      :license_name => license.name,
      :license_url => license.url,
      :thumbnail_url => FlickRaw.url_q(info),
      :fullsize_url => FlickRaw.url_z(info),
      :link_url => FlickRaw.url_photopage(info)
    }

  end

  def set_flickr_metadata
    self.update_attributes(flickr_metadata)
  end

end

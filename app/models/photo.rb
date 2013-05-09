class Photo < ActiveRecord::Base
  attr_accessible :flickr_photo_id, :fullsize_url, :owner_id, :thumbnail_url
  belongs_to :owner, :class_name => 'Member'

  # This is split into a side-effect free method and a side-effecting method
  # for easier stubbing and testing.
  def flickr_urls
    flickr = owner.flickr
    info = flickr.photos.getInfo(:photo_id => flickr_photo_id)
    thumb = FlickRaw.url_q(info)
    full = FlickRaw.url_z(info)
    return [thumb, full]
  end

  def set_flickr_urls
    urls = flickr_urls
    self.thumbnail_url = urls[0]
    self.fullsize_url = urls[1]
  end

end

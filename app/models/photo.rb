class Photo < ActiveRecord::Base
  attr_accessible :flickr_photo_id, :fullsize_url, :owner_id, :thumbnail_url
  belongs_to :owner, :class_name => 'Member'
end

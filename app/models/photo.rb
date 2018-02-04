class Photo < ActiveRecord::Base
  belongs_to :owner, class_name: 'Member'

  PHOTO_CAPABLE = %w(Garden Planting Harvest Seed).freeze

  has_many :photographings, foreign_key: :photo_id, dependent: :destroy
  # creates a relationship for each assignee type
  PHOTO_CAPABLE.each do |type|
    has_many type.downcase.pluralize.to_s.to_sym,
      through: :photographings,
      source: :photographable,
      source_type: type
  end

  default_scope { joins(:owner) } # Ensures the owner still exists

  # This is split into a side-effect free method and a side-effecting method
  # for easier stubbing and testing.
  def flickr_metadata
    flickr = owner.flickr
    info = flickr.photos.getInfo(photo_id: flickr_photo_id)
    licenses = flickr.photos.licenses.getInfo
    license = licenses.find { |l| l.id == info.license }
    {
      title: calculate_title(info),
      license_name: license.name,
      license_url: license.url,
      thumbnail_url: FlickRaw.url_q(info),
      fullsize_url: FlickRaw.url_z(info),
      link_url: FlickRaw.url_photopage(info),
      date_taken: info.dates.taken
    }
  end

  def associations?
    photographings.size.positive?
  end

  def destroy_if_unused
    destroy unless associations?
  end

  def calculate_title(info)
    if id && title # already has a title saved
      title
    elsif info.title # use title from flickr
      info.title
    else
      'untitled'
    end
  end

  def set_flickr_metadata!
    update_attributes(flickr_metadata)
  end

  def to_s
    "#{title} by #{owner.login_name}"
  end
end

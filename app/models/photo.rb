# frozen_string_literal: true

class Photo < ApplicationRecord
  include Likeable
  include Ownable
  include SearchPhotos

  acts_as_votable

  PHOTO_CAPABLE = %w(Garden Planting Harvest Seed Post Crop).freeze

  has_many :photo_associations, dependent: :delete_all, inverse_of: :photo

  # This doesn't work, ActiveRecord tries to use the polymoriphic photographable
  # relationship instead.
  # has_many :crops, through: :photo_associations, counter_cache: true
  def crops
    Crop.distinct.joins(:photo_associations).where(photo_associations: { photo: self })
  end

  validates :fullsize_url, url: true, presence: true
  validates :thumbnail_url, url: true, presence: true
  validates :link_url, url: true, presence: true
  validates :owner, presence: true
  validates :title, presence: true
  validates :license_name, presence: true # Should assert this is one of CC-BY, CC-BY-NC, etc
  validates :license_url,  url: true, allow_blank: true

  # creates a relationship for each assignee type
  PHOTO_CAPABLE.each do |type|
    has_many type.downcase.pluralize.to_s.to_sym,
             through:     :photo_associations,
             source:      :photographable,
             source_type: type
  end

  scope :by_crop, ->(crop) { joins(:photo_associations).where(photo_associations: { crop: }) }
  scope :by_model, lambda { |model_name|
    joins(:photo_associations).where(photo_associations: { photographable_type: model_name.to_s })
  }

  delegate :login_name, :slug, to: :owner, prefix: true

  # This is split into a side-effect free method and a side-effecting method
  # for easier stubbing and testing.
  def flickr_metadata
    flickr = owner.flickr
    info = flickr.photos.getInfo(photo_id: source_id)
    licenses = flickr.photos.licenses.getInfo
    license = licenses.find { |l| l.id == info.license }
    {
      title:         calculate_title(info),
      license_name:  license.name,
      license_url:   license.url,
      thumbnail_url: FlickRaw.url_q(info),
      fullsize_url:  FlickRaw.url_z(info),
      link_url:      FlickRaw.url_photopage(info),
      date_taken:    info.dates.taken
    }
  end

  def associations?
    photo_associations.size.positive?
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
    update(flickr_metadata)
  end

  def to_s
    "#{title} by #{owner.login_name}"
  end

  def flickr_photo_id
    source_id if source == 'flickr'
  end
end

# frozen_string_literal: true

class Photo < ApplicationRecord
  include Likeable
  include Ownable

  PHOTO_CAPABLE = %w(Garden Planting Harvest Seed Post Crop Job).freeze

  has_many :photo_associations, dependent: :delete_all, inverse_of: :photo
  has_many :comments, as: :commentable, dependent: :destroy

  # Uploaded to the photo library: the file as sent, until PhotoUploadJob has
  # made the versions shown from fullsize_url and thumbnail_url.
  has_one_attached :upload, dependent: :purge
  has_one_attached :fullsize_image, dependent: :purge
  has_one_attached :thumbnail_image, dependent: :purge

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
  validates :upload, presence: true, on: :create, if: :uploaded?
  validate :upload_acceptable, on: :create, if: :uploaded?

  after_create :link_to_own_page, if: :uploaded?
  after_create_commit :process_upload, if: :uploaded?

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

  # A photo uploaded to the photo library from the member's device. `upload` is
  # anything Active Storage can attach, such as a direct upload's signed blob id.
  def self.build_upload(owner:, upload:, **attributes)
    token = SecureRandom.base36(24)
    new(owner:, source: 'upload', source_id: token, **attributes).tap do |photo|
      photo.upload.attach(upload)
      photo.fullsize_url = PhotoLibrary.url(PhotoLibrary.key(token, :fullsize))
      photo.thumbnail_url = PhotoLibrary.url(PhotoLibrary.key(token, :thumbnail))
      # Until the photo has an id for its own page.
      photo.link_url = photo.fullsize_url
    end
  end

  def uploaded?
    source == 'upload'
  end

  # This is split into a side-effect free method and a side-effecting method
  # for easier stubbing and testing.
  def flickr_metadata
    flickr = owner.flickr
    info = flickr.photos.getInfo(photo_id: source_id)
    licenses = flickr.photos.licenses.getInfo
    license = licenses.find { |l| l.id.to_i == info.license.to_i }
    Rails.logger.error("Cannot find license: #{[info.license, licenses].inspect}") unless license
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

  def subject
    title
  end

  def author
    owner
  end

  def flickr_photo_id
    source_id if source == 'flickr'
  end

  private

  def upload_acceptable
    return unless upload.attached?

    errors.add(:upload, :invalid_type) unless PhotoLibrary::CONTENT_TYPES.include?(upload.blob.content_type)
    errors.add(:upload, :too_big) if upload.blob.byte_size > PhotoLibrary::MAX_FILE_SIZE
  end

  def link_to_own_page
    update!(link_url: Rails.application.routes.url_helpers.photo_url(
      self, **Rails.application.config.action_mailer.default_url_options
    ))
  end

  def process_upload
    PhotoUploadJob.perform_later(self)
  end
end

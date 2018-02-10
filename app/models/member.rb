class Member < ActiveRecord::Base
  acts_as_paranoid # implements soft deletion
  before_destroy :newsletter_unsubscribe
  include Geocodable
  extend FriendlyId

  friendly_id :login_name, use: %i(slugged finders)

  #
  # Relationships
  has_many :posts, foreign_key: 'author_id'
  has_many :comments, foreign_key: 'author_id'
  has_many :forums, foreign_key: 'owner_id'
  has_many :gardens, foreign_key: 'owner_id'
  has_many :plantings, foreign_key: 'owner_id'
  has_many :seeds, foreign_key: 'owner_id'
  has_many :harvests, foreign_key: 'owner_id'
  has_and_belongs_to_many :roles # rubocop:disable Rails/HasAndBelongsToMany
  has_many :notifications, foreign_key: 'recipient_id'
  has_many :sent_notifications, foreign_key: 'sender_id'
  has_many :authentications
  has_many :photos
  has_many :requested_crops, class_name: Crop, foreign_key: 'requester_id'
  has_many :likes, dependent: :destroy
  has_many :follows, class_name: "Follow", foreign_key: "follower_id", dependent: :destroy
  has_many :inverse_follows, class_name: "Follow", foreign_key: "followed_id", dependent: :destroy
  has_many :followed, through: :follows
  has_many :followers, through: :inverse_follows, source: :follower

  #
  # Scopes
  scope :confirmed, -> { where.not(confirmed_at: nil) }
  scope :located, -> { where.not(location: '').where.not(latitude: nil).where.not(longitude: nil) }
  scope :recently_signed_in, -> { reorder(updated_at: :desc) }
  scope :recently_joined, -> { reorder(confirmed_at: :desc) }
  scope :wants_newsletter, -> { where(newsletter: true) }
  scope :interesting, -> { confirmed.located.recently_signed_in.has_plantings }
  scope :has_plantings, -> { joins(:plantings).group("members.id") }

  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
    :recoverable, :rememberable, :trackable, :validatable,
    :confirmable, :lockable, :timeoutable, :omniauthable

  # set up geocoding
  geocoded_by :location

  # Virtual attribute for authenticating by either username or email
  # This is in addition to a real persisted field like 'username'
  attr_accessor :login

  #
  # Validations
  # Requires acceptance of the Terms of Service
  validates :tos_agreement, acceptance: { allow_nil: true, accept: true }
  validates :login_name,
    length: {
      minimum: 2, maximum: 25, message: "should be between 2 and 25 characters long"
    },
    exclusion: {
      in: %w(growstuff admin moderator staff nearby), message: "name is reserved"
    },
    format: {
      with: /\A\w+\z/, message: "may only include letters, numbers, or underscores"
    },
    uniqueness: {
      case_sensitive: false
    }

  #
  # Triggers
  after_validation :geocode
  after_validation :empty_unwanted_geocodes
  after_save :update_newsletter_subscription

  # Give each new member a default garden
  # we use find_or_create to avoid accidentally creating a second one,
  # which can happen sometimes especially with FactoryBot associations
  after_create { |member| Garden.create(name: "Garden", owner_id: member.id) }

  # allow login via either login_name or email address
  def self.find_first_by_auth_conditions(warden_conditions)
    conditions = warden_conditions.dup
    login = conditions.delete(:login)
    return  where(conditions).login_name_or_email(login).first if login
    find_by(conditions)
  end

  def to_s
    login_name
  end

  def role?(role_sym)
    roles.any? { |r| r.name.gsub(/\s+/, "_").underscore.to_sym == role_sym }
  end

  def auth(provider)
    authentications.find_by(provider: provider)
  end

  # Authenticates against Flickr and returns an object we can use for subsequent api calls
  def flickr
    if @flickr.nil?
      flickr_auth = auth('flickr')
      if flickr_auth
        FlickRaw.api_key = ENV['GROWSTUFF_FLICKR_KEY']
        FlickRaw.shared_secret = ENV['GROWSTUFF_FLICKR_SECRET']
        @flickr = FlickRaw::Flickr.new
        @flickr.access_token = flickr_auth.token
        @flickr.access_secret = flickr_auth.secret
      end
    end
    @flickr
  end

  # Fetches a collection of photos from Flickr
  # Returns a [[page of photos], total] pair.
  # Total is needed for pagination.
  def flickr_photos(page_num = 1, set = nil)
    result = if set
               flickr.photosets.getPhotos(
                 photoset_id: set,
                 page: page_num,
                 per_page: 30
               )
             else
               flickr.people.getPhotos(
                 user_id: 'me',
                 page: page_num,
                 per_page: 30
               )
             end
    return [result.photo, result.total] if result
    [[], 0]
  end

  # Returns a hash of Flickr photosets' ids and titles
  def flickr_sets
    sets = {}
    flickr.photosets.getList.each do |p|
      sets[p.title] = p.id
    end
    sets
  end

  def self.login_name_or_email(login)
    where(["lower(login_name) = :value OR lower(email) = :value", { value: login.downcase }])
  end

  def self.case_insensitive_login_name(login)
    where(["lower(login_name) = :value", { value: login.downcase }])
  end

  def self.nearest_to(place)
    nearby_members = []
    if place
      latitude, longitude = Geocoder.coordinates(place, params: { limit: 1 })
      if latitude && longitude
        nearby_members = Member.located.sort_by { |x| x.distance_from([latitude, longitude]) }
      end
    end
    nearby_members
  end

  def update_newsletter_subscription
    return unless confirmed_at_changed? || newsletter_changed?

    if newsletter
      newsletter_subscribe if confirmed_at_changed? || confirmed_at && newsletter_changed?
    elsif confirmed_at
      newsletter_unsubscribe
    end
  end

  def newsletter_subscribe(gb = Gibbon::API.new, testing = false)
    return true if Rails.env.test? && !testing
    gb.lists.subscribe(
      id: Growstuff::Application.config.newsletter_list_id,
      email: { email: email },
      merge_vars: { login_name: login_name },
      double_optin: false # they already confirmed their email with us
    )
  end

  def newsletter_unsubscribe(gb = Gibbon::API.new, testing = false)
    return true if Rails.env.test? && !testing
    gb.lists.unsubscribe(id: Growstuff::Application.config.newsletter_list_id,
                         email: { email: email })
  end

  def already_following?(member)
    follows.exists?(followed_id: member.id)
  end

  def get_follow(member)
    follows.find_by(followed_id: member.id) if already_following?(member)
  end
end

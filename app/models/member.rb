# frozen_string_literal: true

class Member < ApplicationRecord
  include Discard::Model
  acts_as_messageable # messages can be sent to this model
  include Geocodable
  include MemberFlickr
  include MemberNewsletter

  extend FriendlyId
  friendly_id :login_name, use: %i(slugged finders)

  #
  # Relationships
  has_many :posts, foreign_key: 'author_id', dependent: :destroy, inverse_of: :author
  has_many :comments, foreign_key: 'author_id', dependent: :destroy, inverse_of: :author
  has_many :forums, foreign_key: 'owner_id', dependent: :nullify, inverse_of: :owner
  has_many :gardens, foreign_key: 'owner_id', dependent: :destroy, inverse_of: :owner
  has_many :plantings, foreign_key: 'owner_id', dependent: :destroy, inverse_of: :owner
  has_many :seeds, foreign_key: 'owner_id', dependent: :destroy, inverse_of: :owner
  has_many :harvests, foreign_key: 'owner_id', dependent: :destroy, inverse_of: :owner
  has_and_belongs_to_many :roles
  has_many :notifications, foreign_key: 'recipient_id', inverse_of: :recipient
  has_many :sent_notifications, foreign_key: 'sender_id', inverse_of: :sender
  has_many :authentications, dependent: :destroy
  has_many :photos, inverse_of: :owner
  has_many :likes, dependent: :destroy

  #
  # Following other members
  has_many :follows, class_name: "Follow", foreign_key: "follower_id", dependent: :destroy,
                     inverse_of: :follower
  has_many :inverse_follows, class_name: "Follow", foreign_key: "followed_id",
                             dependent: :destroy, inverse_of: :followed
  has_many :followed, through: :follows
  has_many :followers, through: :inverse_follows, source: :follower

  #
  # Global data records this member created
  has_many :requested_crops, class_name: 'Crop', foreign_key: 'requester_id', dependent: :nullify,
                             inverse_of: :requester
  has_many :created_crops, class_name: 'Crop', foreign_key: 'creator_id', dependent: :nullify,
                           inverse_of: :creator
  has_many :created_alternate_names, class_name: 'AlternateName', foreign_key: 'creator_id', inverse_of: :creator
  has_many :created_scientific_names, class_name: 'ScientificName', foreign_key: 'creator_id', inverse_of: :creator

  #
  # Scopes
  scope :confirmed, -> { where.not(confirmed_at: nil) }
  scope :located, -> { where.not(location: '').where.not(latitude: nil).where.not(longitude: nil) }
  scope :recently_signed_in, -> { reorder(updated_at: :desc) }
  scope :recently_joined, -> { reorder(confirmed_at: :desc) }
  scope :interesting, -> { confirmed.located.recently_signed_in.has_plantings }
  scope :has_plantings, -> { joins(:plantings).group("members.id") }
  scope :wants_reminders, -> { where(send_planting_reminder: true) }

  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :confirmable, :lockable, :timeoutable, :omniauthable

  # discarded (deleted) member cannot log in
  def active_for_authentication?
    super && !discarded?
  end

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
            length:     {
              minimum: 2, maximum: 25, message: "should be between 2 and 25 characters long"
            },
            exclusion:  {
              in: %w(growstuff admin moderator staff nearby), message: "name is reserved"
            },
            format:     {
              with: /\A\w+\z/, message: "may only include letters, numbers, or underscores"
            },
            uniqueness: {
              case_sensitive: false
            }

  #
  # Triggers
  after_validation :geocode
  after_validation :empty_unwanted_geocodes

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
    discarded? ? 'deleted' : login_name
  end

  def to_param
    slug
  end

  def mailboxer_email(_messageable)
    send_notification_email ? email : false
  end

  def role?(role_sym)
    roles.any? { |r| r.name.gsub(/\s+/, "_").underscore.to_sym == role_sym }
  end

  def auth(provider)
    authentications.find_by(provider: provider)
  end

  def unread_count
    receipts.where(is_read: false).count
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
      nearby_members = Member.located.sort_by { |x| x.distance_from([latitude, longitude]) } if latitude && longitude
    end
    nearby_members
  end

  def already_following?(member)
    follows.exists?(followed_id: member.id)
  end

  def get_follow(member)
    follows.find_by(followed_id: member.id) if already_following?(member)
  end
end

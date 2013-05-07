class Member < ActiveRecord::Base
  extend FriendlyId
  friendly_id :login_name, use: :slugged

  has_many :posts,   :foreign_key => 'author_id'
  has_many :comments, :foreign_key => 'author_id'
  has_many :gardens, :foreign_key => 'owner_id'
  has_many :plantings, :through => :gardens
  has_many :forums, :foreign_key => 'owner_id'
  has_and_belongs_to_many :roles
  has_many :notifications, :foreign_key => 'recipient_id'
  has_many :sent_notifications, :foreign_key => 'sender_id'
  has_many :authentications
  has_many :orders

  default_scope order("lower(login_name) asc")
  scope :confirmed, where('confirmed_at IS NOT NULL')
  scope :located, where('location IS NOT NULL')
  scope :recently_signed_in, reorder('updated_at DESC')

  # this is used on the signed-out homepage so we're basically
  # just trying to select some members who look good.
  scope :interesting, confirmed.located.recently_signed_in

  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :confirmable, :lockable, :timeoutable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :login_name, :email, :password, :password_confirmation,
    :remember_me, :login, :tos_agreement, :show_email,
    :location, :latitude, :longitude, :send_notification_email

  # set up geocoding
  geocoded_by :location
  after_validation :geocode
  after_validation :empty_unwanted_geocodes

  # Virtual attribute for authenticating by either username or email
  # This is in addition to a real persisted field like 'username'
  attr_accessor :login

  # Requires acceptance of the Terms of Service
  validates_acceptance_of :tos_agreement, :allow_nil => false,
    :accept => true

  validates :login_name,
    :length => {
      :minimum => 2,
      :maximum => 25,
      :message => "should be between 2 and 25 characters long"
    },
    :exclusion => {
      :in => %w(growstuff admin moderator staff nearby),
      :message => "name is reserved"
    },
    :format => {
      :with => /^\w+$/,
      :message => "may only include letters, numbers, or underscores"
    },
    :uniqueness => {
      :case_sensitive => false
    }

  # Give each new member a default garden
  after_create {|member| Garden.create(:name => "Garden", :owner_id => member.id) }

  # allow login via either login_name or email address
  def self.find_first_by_auth_conditions(warden_conditions)
    conditions = warden_conditions.dup
    if login = conditions.delete(:login)
      where(conditions).where(["lower(login_name) = :value OR lower(email) = :value", { :value => login.downcase }]).first
    else
      where(conditions).first
    end
  end

  def to_s
    return login_name
  end

  def has_role?(role_sym)
    roles.any? { |r| r.name.gsub(/\s+/, "_").underscore.to_sym == role_sym }
  end

  protected
  def empty_unwanted_geocodes
    if self.location.to_s == ''
      self.latitude = nil
      self.longitude = nil
    end
  end

end

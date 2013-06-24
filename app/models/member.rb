class Member < ActiveRecord::Base
  extend FriendlyId
  friendly_id :login_name, use: :slugged

  has_many :posts,   :foreign_key => 'author_id'
  has_many :comments, :foreign_key => 'author_id'
  has_many :forums, :foreign_key => 'owner_id'

  has_many :gardens, :foreign_key => 'owner_id'
  has_many :plantings, :through => :gardens

  has_and_belongs_to_many :roles

  has_many :notifications, :foreign_key => 'recipient_id'
  has_many :sent_notifications, :foreign_key => 'sender_id'

  has_many :authentications

  has_many :orders
  has_one  :account
  has_one  :account_type, :through => :account

  has_many :photos

  default_scope order("lower(login_name) asc")
  scope :confirmed, where('confirmed_at IS NOT NULL')
  scope :located, where('location IS NOT NULL')
  scope :recently_signed_in, reorder('updated_at DESC')
  scope :not_staff, joins(:account => :account_type).
    where('account_types.name != "Staff"')

  # this is used on the signed-out homepage so we're basically
  # just trying to select some members who look good.
  scope :interesting, confirmed.located.recently_signed_in.not_staff

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

  # and an account record (for paid accounts etc)
  # we use find_or_create to avoid accidentally creating a second one,
  # which can happen sometimes especially with FactoryGirl associations
  after_create {|member| Account.find_or_create_by_member_id(:member_id => member.id) }

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

  def current_order
    orders.where(:completed_at => nil).first
  end

  # when purchasing a product that gives you a paid account, this method
  # does all the messing around to actually make sure the account is
  # updated correctly -- account type, paid until, etc.  Usually this is
  # called by order.update_account, which loops through all order items
  # and does this for each one.
  def update_account_after_purchase(product)
    if product.account_type
      account.account_type = product.account_type
    end
    if product.paid_months
      start_date = account.paid_until || Time.zone.now
      account.paid_until = start_date + product.paid_months.months
    end
    account.save
  end

  def is_paid?
    if account.account_type.is_permanent_paid
      return true
    elsif account.account_type.is_paid and account.paid_until >= Time.zone.now
      return true
    else
      return false
    end
  end

  def auth(provider)
    return authentications.find_by_provider(provider)
  end

  def flickr
    if @flickr.nil?
      flickr_auth = auth('flickr')
      if flickr_auth
        FlickRaw.api_key = ENV['FLICKR_KEY']
        FlickRaw.shared_secret = ENV['FLICKR_SECRET']
        @flickr = FlickRaw::Flickr.new
        @flickr.access_token = flickr_auth.token
        @flickr.access_secret = flickr_auth.secret
      end
    end
    return @flickr
  end

  def flickr_photos
    return flickr.people.getPhotos(:user_id => 'me', :per_page => 30)
  end

  protected
  def empty_unwanted_geocodes
    if self.location.to_s == ''
      self.latitude = nil
      self.longitude = nil
    end
  end

end

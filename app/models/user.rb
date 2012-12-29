class User < ActiveRecord::Base
  extend FriendlyId
  friendly_id :username, use: :slugged

  has_many :updates
  has_many :gardens

  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :confirmable, :lockable, :timeoutable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :username, :email, :password, :password_confirmation,
    :remember_me, :login, :tos_agreement
  # attr_accessible :title, :body

  # Virtual attribute for authenticating by either username or email
  # This is in addition to a real persisted field like 'username'
  attr_accessor :login

  # Requires acceptance of the Terms of Service
  validates_acceptance_of :tos_agreement, :allow_nil => false,
    :accept => true

  # Give each new user a default garden
  after_create {|user| Garden.new(:name => "Garden", :user_id => user.id).save }

  scope :confirmed, where('confirmed_at IS NOT NULL')

  # allow login via either username or email address
  def self.find_first_by_auth_conditions(warden_conditions)
    conditions = warden_conditions.dup
    if login = conditions.delete(:login)
      where(conditions).where(["lower(username) = :value OR lower(email) = :value", { :value => login.downcase }]).first
    else
      where(conditions).first
    end
  end

  def to_s
    return username
  end
end

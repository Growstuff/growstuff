class Planting < ActiveRecord::Base
  extend FriendlyId
  friendly_id :planting_slug, use: :slugged

  attr_accessible :crop_id, :description, :garden_id, :planted_at,
    :quantity, :sunniness, :planted_from

  belongs_to :garden
  belongs_to :crop

  has_and_belongs_to_many :photos
  before_destroy {|planting| planting.photos.clear}

  default_scope order("created_at desc")

  delegate :system_name,
    :en_wikipedia_url,
    :default_scientific_name,
    :plantings_count,
    :to => :crop,
    :prefix => true
  delegate :owner, :to => :garden

  default_scope order("created_at desc")

  validates :quantity, :numericality => { :only_integer => true }

  SUNNINESS_VALUES = %w(sun semi-shade shade)
  validates :sunniness, :inclusion => { :in => SUNNINESS_VALUES,
        :message => "%{value} is not a valid sunniness value" },
        :allow_nil => true,
        :allow_blank => true

  PLANTED_FROM_VALUES = [
    'seed',
    'seedling',
    'cutting',
    'root division',
    'runner',
    'bare root plant',
    'advanced plant',
    'graft',
    'layering'
  ]
  validates :planted_from, :inclusion => { :in => PLANTED_FROM_VALUES,
        :message => "%{value} is not a valid planting method" },
        :allow_nil => true,
        :allow_blank => true

  def planting_slug
    "#{owner.login_name}-#{garden}-#{crop}".downcase.gsub(' ', '-')
  end

  def location
    return "#{garden.owner.login_name}'s #{garden}"
  end

  def to_s
    self.crop_system_name + " in " + self.location
  end

  def default_photo
    return photos.first
  end
end

class Planting < ActiveRecord::Base
  extend FriendlyId
  friendly_id :planting_slug, use: :slugged

  attr_accessible :crop_id, :description, :garden_id, :planted_at,
    :quantity, :sunniness, :planted_from, :owner_id, :finished,
    :finished_at

  belongs_to :garden
  belongs_to :owner, :class_name => 'Member', :counter_cache => true
  belongs_to :crop, :counter_cache => true

  has_and_belongs_to_many :photos
  before_destroy {|planting| planting.photos.clear}

  default_scope order("created_at desc")
  scope :finished, where(:finished => true)
  scope :current, where(:finished => false)

  delegate :name,
    :en_wikipedia_url,
    :default_scientific_name,
    :plantings_count,
    :to => :crop,
    :prefix => true

  default_scope order("created_at desc")

  validates :crop_id, :presence => {:message => "must be present and exist in our database"}

  validates :quantity,
    :numericality => { :only_integer => true },
    :allow_nil => true

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
    'bulb',
    'root/tuber',
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

  # location = garden owner + garden name, i.e. "Skud's backyard"
  def location
    return "#{garden.owner.login_name}'s #{garden}"
  end

  # stringify as "beet in Skud's backyard" or similar
  def to_s
    self.crop_name + " in " + self.location
  end

  def default_photo
    return photos.first
  end

  def interesting?
    return photos.present?
  end

  # return a list of interesting plantings, for the homepage etc.
  # we can't do this via a scope (as far as we know) so sadly we have to
  # do it this way.
  def Planting.interesting
    howmany = 12 # max amount to collect

    interesting_plantings = Array.new
    seen_owners = Hash.new(false) # keep track of which owners we've seen already

    Planting.all.each do |p|
      break if interesting_plantings.count == howmany # got enough yet?
      next unless p.interesting?    # skip those that don't have photos
      next if seen_owners[p.owner]  # skip if we already have one from this owner
      seen_owners[p.owner] = true   # we've seen this owner
      interesting_plantings.push(p)
    end

    return interesting_plantings
  end
end

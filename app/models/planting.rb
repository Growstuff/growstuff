class Planting < ActiveRecord::Base
  extend FriendlyId
  friendly_id :planting_slug, use: [:slugged, :finders]

  belongs_to :garden
  belongs_to :owner, :class_name => 'Member', :counter_cache => true
  belongs_to :crop, :counter_cache => true

  has_and_belongs_to_many :photos

  before_destroy do |planting|
    photolist = planting.photos.to_a # save a temp copy of the photo list
    planting.photos.clear # clear relationship b/w planting and photo

    photolist.each do |photo|
      photo.destroy_if_unused
    end
  end

  default_scope { order("created_at desc") }
  scope :finished, -> { where(:finished => true) }
  scope :current, -> { where(:finished => false) }

  delegate :name,
    :en_wikipedia_url,
    :default_scientific_name,
    :plantings_count,
    :to => :crop,
    :prefix => true

  default_scope { order("created_at desc") }

  validates :crop, :approved => true

  validates :crop, :presence => {:message => "must be present and exist in our database"}

  validates :quantity,
    :numericality => {
      :only_integer => true,
      :greater_than_or_equal_to => 0 },
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

  validate :finished_must_be_after_planted

  # check that any finished_at date occurs after planted_at
  def finished_must_be_after_planted
    return unless planted_at and finished_at # only check if we have both
    errors.add(:finished_at, "must be after the planting date") unless planted_at < finished_at
  end

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

  def calculate_days_before_maturity(planting, crop)
    p_crop = Planting.where(:crop_id => crop).where.not(:id => planting)
    differences = p_crop.collect do |p|
      if p.finished and !p.finished_at.nil?
        (p.finished_at - p.planted_at).to_i
      end
    end

    if differences.compact.empty?
      nil
    else  
      differences.compact.sum/differences.compact.size
    end
  end

  # return a list of interesting plantings, for the homepage etc.
  # we can't do this via a scope (as far as we know) so sadly we have to
  # do it this way.
  def Planting.interesting(howmany=12, require_photo=true)
    interesting_plantings = Array.new
    seen_owners = Hash.new(false) # keep track of which owners we've seen already

    Planting.includes(:photos).each do |p|
      break if interesting_plantings.size == howmany # got enough yet?
      if require_photo
        next unless p.photos.present? # skip those without photos, if required
      end
      next if seen_owners[p.owner]  # skip if we already have one from this owner
      seen_owners[p.owner] = true   # we've seen this owner
      interesting_plantings.push(p)
    end

    return interesting_plantings
  end
end

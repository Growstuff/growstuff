class Seed < ActiveRecord::Base
  extend FriendlyId
  friendly_id :seed_slug, use: [:slugged, :finders]

  belongs_to :crop
  belongs_to :owner, :class_name => 'Member', :foreign_key => 'owner_id'

  has_and_belongs_to_many :photos

  before_destroy do |seed|
    photolist = seed.photos.to_a # save a temp copy of the photo list
    seed.photos.clear # clear relationship b/w seed and photo

    photolist.each do |photo|
      photo.destroy_if_unused
    end
  end

  default_scope { order("created_at desc") }

  validates :crop, :presence => {:message => "must be present and exist in our database"}
  validates :quantity,
    :numericality => { :only_integer => true },
    :allow_nil => true

  scope :tradable, -> { where("tradable_to != 'nowhere'") }

  TRADABLE_TO_VALUES = %w(nowhere locally nationally internationally)
  validates :tradable_to, :inclusion => { :in => TRADABLE_TO_VALUES,
        :message => "You may only trade seed nowhere, locally, nationally, or internationally" },
        :allow_nil => false,
        :allow_blank => false

  def tradable?
    if self.tradable_to == 'nowhere'
      return false
    else
      return true
    end
  end

  def interesting?
    # assuming we're passed something that's already known to be tradable
    # eg. from Seed.tradable scope
    return false if owner.location.blank? # don't want unspecified locations
    return true
  end

  # Seed.interesting
  # returns a list of interesting seeds, for use on the homepage etc
  def Seed.interesting
    howmany = 12 # max number to find
    interesting_seeds = Array.new

    Seed.tradable.each do |s|
      break if interesting_seeds.length == howmany
      if s.interesting?
        interesting_seeds.push(s)
      end
    end

    return interesting_seeds

  end

  def seed_slug
    "#{owner.login_name}-#{crop}".downcase.gsub(' ', '-')
  end
  def default_photo
    return photos.first
  end
end

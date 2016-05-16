class Seed < ActiveRecord::Base
  extend FriendlyId
  friendly_id :seed_slug, use: [:slugged, :finders]

  belongs_to :crop
  belongs_to :owner, :class_name => 'Member', :foreign_key => 'owner_id'

  default_scope { order("created_at desc") }

  validates :crop, :approved => true

  validates :crop, :presence => {:message => "must be present and exist in our database"}
  validates :quantity,
    :numericality => {
      :only_integer => true,
      :greater_than_or_equal_to => 0 },
    :allow_nil => true
  validates :days_until_maturity_min,
    :numericality => {
      :only_integer => true,
      :greater_than_or_equal_to => 0 },
    :allow_nil => true
  validates :days_until_maturity_max,
    :numericality => {
      :only_integer => true,
      :greater_than_or_equal_to => 0 },
    :allow_nil => true

  scope :tradable, -> { where("tradable_to != 'nowhere'") }

  TRADABLE_TO_VALUES = %w(nowhere locally nationally internationally)
  validates :tradable_to, :inclusion => { :in => TRADABLE_TO_VALUES,
        :message => "You may only trade seed nowhere, locally, nationally, or internationally" },
        :allow_nil => false,
        :allow_blank => false

  ORGANIC_VALUES = [
    'certified organic',
    'non-certified organic',
    'conventional/non-organic',
    'unknown']
  validates :organic, :inclusion => { :in => ORGANIC_VALUES,
        :message => "You must say whether the seeds are organic or not, or that you don't know" },
        :allow_nil => false,
        :allow_blank => false

  GMO_VALUES = [
    'certified GMO-free',
    'non-certified GMO-free',
    'GMO',
    'unknown']
  validates :gmo, :inclusion => { :in => GMO_VALUES,
        :message => "You must say whether the seeds are genetically modified or not, or that you don't know" },
        :allow_nil => false,
        :allow_blank => false

  HEIRLOOM_VALUES = %w(heirloom hybrid unknown)
  validates :heirloom, :inclusion => { :in => HEIRLOOM_VALUES,
        :message => "You must say whether the seeds are heirloom, hybrid, or unknown" },
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
      break if interesting_seeds.size == howmany
      if s.interesting?
        interesting_seeds.push(s)
      end
    end

    return interesting_seeds

  end

  def seed_slug
    "#{owner.login_name}-#{crop}".downcase.gsub(' ', '-')
  end
end

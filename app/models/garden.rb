class Garden < ActiveRecord::Base
  extend FriendlyId
  friendly_id :garden_slug, use: :slugged

  attr_accessible :name, :slug, :owner_id, :description
  belongs_to :owner, :class_name => 'Member', :foreign_key => 'owner_id'
  has_many :plantings, :order => 'created_at DESC', :dependent => :destroy
  has_many :crops, :through => :plantings

  # before_create :replace_blank_name

  default_scope order("lower(name) asc")

  validates :name,
    :format => {
      :with => /\S/
    }

  def garden_slug
    "#{owner.login_name}-#{name}".downcase.gsub(' ', '-')
  end

  # featured plantings returns the most recent 4 plantings for a garden,
  # choosing them so that no crop is repeated.
  def featured_plantings
    unique_plantings = []
    seen_crops = []

    plantings.each do |p|
      if (! seen_crops.include?(p.crop))
        unique_plantings.push(p)
        seen_crops.push(p.crop)
      end
    end

    return unique_plantings[0..3]
  end

  def replace_blank_name
    if self.name.nil? or self.name =~ /^\s*$/
      self.name = "(no name)"
    end
  end

  def to_s
    name
  end

end

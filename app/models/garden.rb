class Garden < ActiveRecord::Base
  extend FriendlyId
  friendly_id :garden_slug, use: :slugged

  attr_accessible :name, :slug, :owner_id
  belongs_to :owner, :class_name => 'Member', :foreign_key => 'owner_id'
  has_many :plantings, :order => 'created_at DESC'
  has_many :crops, :through => :plantings

  def garden_slug
    formatted_name = name.downcase.gsub(' ', '-')
    "#{owner.login_name}-#{formatted_name}"
  end

  # featured plantings returns the most recent 4 plantings for a garden,
  # choosing them so that no crop is repeated.
  def featured_plantings
    return plantings.group(:crop_id).limit(4)
  end

end

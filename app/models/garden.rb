class Garden < ActiveRecord::Base
  extend FriendlyId
  friendly_id :garden_slug, use: :slugged

  attr_accessible :name, :slug, :member_id
  belongs_to :member

  def garden_slug
    formatted_name = name.downcase.gsub(' ', '-')
    "#{member.username}-#{formatted_name}"
  end

  def owner
    return member
  end
end

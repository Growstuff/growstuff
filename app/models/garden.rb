class Garden < ActiveRecord::Base
  extend FriendlyId
  friendly_id :garden_slug, use: :slugged

  attr_accessible :name, :slug, :owner_id
  belongs_to :owner, :class_name => 'Member', :foreign_key => 'owner_id'

  def garden_slug
    formatted_name = name.downcase.gsub(' ', '-')
    "#{owner.login_name}-#{formatted_name}"
  end

end

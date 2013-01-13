class Garden < ActiveRecord::Base
  extend FriendlyId
  friendly_id :garden_slug, use: :slugged

  attr_accessible :name, :slug, :user_id
  belongs_to :user

  def garden_slug
    formatted_name = name.downcase.gsub(' ', '-')
    "#{user.username}-#{formatted_name}"
  end

  def owner
    return user
  end
end

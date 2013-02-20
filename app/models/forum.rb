class Forum < ActiveRecord::Base
  extend FriendlyId
  friendly_id :name, use: :slugged
  attr_accessible :description, :name, :owner_id, :slug
  has_many :posts
  belongs_to :owner, :class_name => "Member"

  def to_s
    return name
  end

end

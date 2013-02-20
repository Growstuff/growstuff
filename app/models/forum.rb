class Forum < ActiveRecord::Base
  attr_accessible :description, :name, :owner_id
  has_many :posts
  belongs_to :owner, :class_name => "Member"

  def to_s
    return name
  end

end

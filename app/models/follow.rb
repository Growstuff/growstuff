class Follow < ActiveRecord::Base
  attr_accessible :followed_id, :member_id
  belongs_to :member
  belongs_to :followed, class_name: "Member"
  validates :member_id, uniqueness: { :scope => :followed_id }
end

class Follow < ActiveRecord::Base
  attr_accessible :followed_id, :member_id
  belongs_to :member
  belongs_to :followed, class_name: "Member"
  validates :member_id, uniqueness: { :scope => :followed_id }

  after_create do
    Notification.create(
      :recipient_id => self.followed_id,
      :sender_id => self.member_id,
      :subject => "#{self.member.login_name} has followed you",
      :body => "#{self.member.login_name} has followed you"
    )
  end


end

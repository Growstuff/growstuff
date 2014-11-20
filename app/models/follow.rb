class Follow < ActiveRecord::Base
  attr_accessible :followed_id, :follower_id
  belongs_to :follower, class_name: "Member"
  belongs_to :followed, class_name: "Member"
  validates :follower_id, uniqueness: { :scope => :followed_id }

  after_create do
    Notification.create(
      :recipient_id => self.followed_id,
      :sender_id => self.follower_id,
      :subject => "#{self.follower.login_name} is now following you",
      :body => "#{self.follower.login_name} just followed you on Growstuff. "
    )
  end


end

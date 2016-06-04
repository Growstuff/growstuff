class Follow < ActiveRecord::Base
  belongs_to :follower, class_name: "Member"
  belongs_to :followed, class_name: "Member"
  validates :follower_id, uniqueness: { scope: :followed_id }

  after_create do
    Notification.create(
      recipient_id: self.followed_id,
      sender_id: self.follower_id,
      subject: "#{self.follower.login_name} is now following you",
      body: "#{self.follower.login_name} just followed you on #{ENV["GROWSTUFF_SITE_NAME"]}. "
    )
  end


end

class Follow < ApplicationRecord
  belongs_to :follower, class_name: "Member"
  belongs_to :followed, class_name: "Member"
  validates :follower_id, uniqueness: { scope: :followed_id }

  after_create do
    Notification.create(
      recipient_id: followed_id,
      sender_id: follower_id,
      subject: "#{follower.login_name} is now following you",
      body: "#{follower.login_name} just followed you on #{ENV['GROWSTUFF_SITE_NAME']}. "
    )
  end
end

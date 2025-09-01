# frozen_string_literal: true

class Follow < ApplicationRecord
  belongs_to :follower, class_name: "Member", inverse_of: :follows
  belongs_to :followed, class_name: "Member", inverse_of: :inverse_follows
  validates :follower_id, uniqueness: { scope: :followed_id }
  validate :follower_is_not_blocked

  after_create do
    Notification.create(
      recipient_id: followed_id,
      sender_id:    follower_id,
      subject:      "#{follower.login_name} is now following you",
      body:         "#{follower.login_name} just followed you on #{ENV.fetch('GROWSTUFF_SITE_NAME', nil)}. ",
      notifiable:   self
    )
  end

  private

  def follower_is_not_blocked
    if followed.already_blocking?(follower)
      errors.add(:base, "You cannot follow a member who has blocked you.")
    end
  end
end

class Notification < ActiveRecord::Base
  attr_accessible :sender_id, :recipient_id,
    :subject, :body, :post_id, :read

  belongs_to :sender, :class_name => 'Member'
  belongs_to :recipient, :class_name => 'Member'
  belongs_to :post

  default_scope order('created_at DESC')
  scope :unread, where(:read => false)

  after_create :send_email

  def self.unread_count
    self.unread.count
  end

  def send_email
    if self.recipient.send_notification_email
      Notifier.notify(self).deliver
    end
  end

end

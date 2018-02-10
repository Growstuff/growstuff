class Notification < ActiveRecord::Base
  belongs_to :sender, class_name: 'Member'
  belongs_to :recipient, class_name: 'Member'
  belongs_to :post

  validates :subject, length: { maximum: 255 }

  scope :unread, -> { where(read: false) }
  scope :by_recipient, ->(recipient) { where(recipient_id: recipient) }

  before_create :replace_blank_subject
  after_create :send_email

  def self.unread_count
    unread.size
  end

  def replace_blank_subject
    self.subject = "(no subject)" if subject.nil? || subject =~ /^\s*$/
  end

  def send_email
    Notifier.notify(self).deliver_now! if recipient.send_notification_email
  end
end

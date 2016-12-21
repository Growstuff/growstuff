class Notification < ActiveRecord::Base
  belongs_to :sender, class_name: 'Member'
  belongs_to :recipient, class_name: 'Member'
  belongs_to :post

  validates :subject, length: { maximum: 255 }

  default_scope { order('created_at DESC') }
  scope :unread, -> { where(read: false) }
  scope :by_recipient, ->(recipient) { where(recipient_id: recipient) }

  before_create :replace_blank_subject
  after_create :send_email

  def self.unread_count
    self.unread.size
  end

  def replace_blank_subject
    self.subject = "(no subject)" if self.subject.nil? or self.subject =~ /^\s*$/
  end

  def send_email
    Notifier.notify(self).deliver_later if self.recipient.send_notification_email
  end
end

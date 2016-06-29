class Notification < ActiveRecord::Base
  belongs_to :sender, class_name: 'Member'
  belongs_to :recipient, class_name: 'Member'
  belongs_to :post

  validates :subject, length: { maximum: 255 }

  default_scope { order('created_at DESC') }
  scope :unread, -> { where(read: false) }

  before_create :replace_blank_subject
  after_create :send_email

  def self.unread_count
    self.unread.size
  end

  def replace_blank_subject
    if self.subject.nil? or self.subject =~ /^\s*$/
      self.subject = "(no subject)"
    end
  end

  def send_email
    if self.recipient.send_notification_email
      Notifier.notify(self).deliver_now
    end
  end

end

class Notification < ActiveRecord::Base
  attr_accessible :sender_id, :recipient_id,
    :subject, :body, :post_id, :read, :in_reply_to_id

  belongs_to :in_reply_to, :class_name => 'Notification'
  belongs_to :sender, :class_name => 'Member'
  belongs_to :recipient, :class_name => 'Member'
  belongs_to :post

  has_many :replies, :foreign_key => :in_reply_to, :class_name => 'Notification'

  default_scope order('created_at DESC')
  scope :unread, where(:read => false)

  before_create :replace_blank_subject
  after_create :send_email

  def self.unread_count
    self.unread.count
  end

  def replace_blank_subject
    if self.subject.nil? or self.subject =~ /^\s*$/
      self.subject = "(no subject)"
    end
  end

  def send_email
    if self.recipient.send_notification_email
      Notifier.notify(self).deliver
    end
  end

end

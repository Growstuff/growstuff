class Notification < ApplicationRecord
  belongs_to :sender, class_name: 'Member', inverse_of: :sent_notifications
  belongs_to :recipient, class_name: 'Member', inverse_of: :notifications
  belongs_to :post, optional: true

  validates :subject, length: { maximum: 255 }
  validates :subject, presence: true
  validates :body, presence: true

  scope :unread, -> { where(read: false) }
  scope :by_recipient, ->(recipient) { where(recipient_id: recipient) }

  before_create :replace_blank_subject
  after_create :send_message

  def self.unread_count
    unread.size
  end

  def replace_blank_subject
    self.subject = "(no subject)" if subject.nil? || subject =~ /^\s*$/
  end

  def send_message
    sender.send_message(recipient, body, subject)
  end

  def migrate_to_mailboxer!
    conversation = Mailboxer::ConversationBuilder.new(
      subject:    subject,
      created_at: created_at,
      updated_at: updated_at
    ).build

    message = Mailboxer::MessageBuilder.new(
      sender:       sender,
      conversation: conversation,
      recipients:   [recipient],
      body:         body,
      subject:      subject,
      # attachment:   attachment,
      created_at:   created_at,
      updated_at:   updated_at
    ).build

    notification = Mailboxer::NotificationBuilder.new(
      recipients: [recipient],
      subject:    subject,
      body:       body,
      sender:     sender
    ).build

    conversation.save!
    message.save!
    notification.save!
    notification.deliver(false, false)
  end
end

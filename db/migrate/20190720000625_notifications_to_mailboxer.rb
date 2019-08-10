class NotificationsToMailboxer < ActiveRecord::Migration[5.2]
  def up
    Notification.all.each do |n|
      next unless n.valid?

      conversation = Mailboxer::ConversationBuilder.new(
        subject:    n.subject,
        created_at: n.created_at,
        updated_at: n.updated_at
      ).build

      message = Mailboxer::MessageBuilder.new(
        sender:       n.sender,
        conversation: conversation,
        recipients:   [n.recipient],
        body:         n.body,
        subject:      n.subject,
        # attachment:   attachment,
        created_at:   n.created_at,
        updated_at:   n.updated_at
      ).build

      conversation.save!
      message.save!
    end
  end
end

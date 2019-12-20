# frozen_string_literal: true

class NotificationsToMailboxer < ActiveRecord::Migration[5.2]
  def up
    Mailboxer.setup do |config|
      # turn off emails
      config.uses_emails = false
    end
    Notification.find_in_batches.each do |group|
      group.each do |n|
        n.body = 'message has no body' if n.body.blank?
        receipt = n.sender.send_message(n.recipient, n.body, n.subject)
        # Copy over which messages are read
        receipt.conversation.receipts.each(&:mark_as_read) if n.read
        # copy over timestamps
        receipt.conversation.messages.each do |msg|
          msg.update!(created_at: n.created_at, updated_at: n.updated_at)
        end
      end
    end
  end
end

class NotificationsToMailboxer < ActiveRecord::Migration[5.2]
  def up
    Mailboxer.setup do |config|
      # turn off emails
      config.uses_emails = false
    end
    Notification.find_in_batches.each do |group|
      group.each do |n|
        n.body = 'message has no body' if n.body.blank?
        receipt = n.send_message
        next unless n.read

        receipt.conversation.receipts.each(&:mark_as_read)
      end
    end
  end
end

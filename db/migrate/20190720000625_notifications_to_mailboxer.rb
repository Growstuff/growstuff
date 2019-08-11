class NotificationsToMailboxer < ActiveRecord::Migration[5.2]
  def up
    Mailboxer.setup do |config|
      # turn off emails
      config.uses_emails = false
    end
    Notification.find_in_batches.each do |group|
      group.each do |n|
        n.body = 'message has no body' if n.body.blank?
        n.send_message
      end
    end
  end
end

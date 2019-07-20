class NotificationsToMailboxer < ActiveRecord::Migration[5.2]
  def change
    Notification.all.each do |n|
      recipient = Member.with_deleted.find(n.recipient_id)
      sender = Member.with_deleted.find(n.sender_id)
      sender.send_message(recipient, n.body, n.subject)
    end
  end
end

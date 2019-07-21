class NotificationsToMailboxer < ActiveRecord::Migration[5.2]
  def change
    Notification.all.each do |n|
      n.sender.send_message(n.recipient, n.body, n.subject)
    end
  end
end

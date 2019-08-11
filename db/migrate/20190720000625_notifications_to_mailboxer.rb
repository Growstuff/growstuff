class NotificationsToMailboxer < ActiveRecord::Migration[5.2]
  def up
    Notification.find_in_batches do |group|
      group.each do |n|
        next unless n.valid?
        n.migrate_to_mailboxer!
      end
    end
  end
end

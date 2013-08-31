class AddInReplyToToNotifications < ActiveRecord::Migration
  def change
    add_column :notifications, :in_reply_to_id, :integer
  end
end

class AddSendEmailToMember < ActiveRecord::Migration
  def change
    add_column :members, :send_notification_email, :boolean, default: true
  end
end

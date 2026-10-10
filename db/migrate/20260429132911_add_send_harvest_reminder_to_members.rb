class AddSendHarvestReminderToMembers < ActiveRecord::Migration[7.2]
  def change
    add_column :members, :send_harvest_reminder, :boolean, default: true, null: false
  end
end

class AddSendPlantingReminderToMember < ActiveRecord::Migration
  def change
    add_column :members, :send_planting_reminder, :boolean, default: true
  end
end

# frozen_string_literal: true

class AddSendPlantingReminderToMember < ActiveRecord::Migration[4.2]
  def change
    add_column :members, :send_planting_reminder, :boolean, default: true
  end
end

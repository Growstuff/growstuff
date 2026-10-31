# frozen_string_literal: true

class AddPlantingReminderSentAtToMembers < ActiveRecord::Migration[8.1]
  def change
    add_column :members, :planting_reminder_sent_at, :datetime,
               comment: 'When we last sent the weekly planting reminder, so we can tell who has not heard from us in a while.'
  end
end

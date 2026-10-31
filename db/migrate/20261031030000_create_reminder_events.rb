# frozen_string_literal: true

# One row each time a reminder email is sent, or a member unsubscribes from one, so the admin screen can count them.
class CreateReminderEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :reminder_events do |t|
      t.references :member, null: false, foreign_key: { on_delete: :cascade }
      t.string :kind, null: false, comment: 'Which reminder: planting_reminder or harvest_reminder.'
      t.string :event, null: false, comment: 'What happened: sent or unsubscribed.'
      t.datetime :created_at, null: false
    end
    add_index :reminder_events, %i(kind event created_at)
  end
end

# frozen_string_literal: true

class RenameNotificationFields < ActiveRecord::Migration[4.2]
  def change
    change_table :notifications do |t|
      t.rename :to_id, :recipient_id
      t.rename :from_id, :sender_id
    end
  end
end

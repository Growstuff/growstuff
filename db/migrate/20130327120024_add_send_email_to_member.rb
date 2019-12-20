# frozen_string_literal: true

class AddSendEmailToMember < ActiveRecord::Migration[4.2]
  def change
    add_column :members, :send_notification_email, :boolean, default: true
  end
end

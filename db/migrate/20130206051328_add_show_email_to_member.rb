# frozen_string_literal: true

class AddShowEmailToMember < ActiveRecord::Migration[4.2]
  def change
    add_column :members, :show_email, :boolean
  end
end

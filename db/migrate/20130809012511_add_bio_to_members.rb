# frozen_string_literal: true

class AddBioToMembers < ActiveRecord::Migration[4.2]
  def change
    add_column :members, :bio, :text
  end
end

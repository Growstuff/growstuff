# frozen_string_literal: true

class AddMemberCountCaches < ActiveRecord::Migration[4.2]
  def change
    add_column :members, :photos_count, :integer
    add_column :members, :forums_count, :integer
  end
end

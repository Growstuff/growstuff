# frozen_string_literal: true

class AddOwnerToPlanting < ActiveRecord::Migration[4.2]
  def change
    add_column :plantings, :owner_id, :integer
  end
end

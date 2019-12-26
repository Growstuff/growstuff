# frozen_string_literal: true

class AddRequesterToCrops < ActiveRecord::Migration[4.2]
  def change
    add_column :crops, :requester_id, :integer
    add_index :crops, :requester_id
  end
end

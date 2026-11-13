# frozen_string_literal: true

class AddPositionToJobs < ActiveRecord::Migration[8.1]
  def change
    add_column :jobs, :position, :integer, null: false, default: 0
  end
end

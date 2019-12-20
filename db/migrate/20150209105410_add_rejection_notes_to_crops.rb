# frozen_string_literal: true

class AddRejectionNotesToCrops < ActiveRecord::Migration[4.2]
  def change
    add_column :crops, :rejection_notes, :text
  end
end

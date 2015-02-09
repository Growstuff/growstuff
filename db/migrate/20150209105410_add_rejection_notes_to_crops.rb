class AddRejectionNotesToCrops < ActiveRecord::Migration
  def change
    add_column :crops, :rejection_notes, :text
  end
end

class AddDescriptionToGardens < ActiveRecord::Migration
  def change
    add_column :gardens, :description, :text
  end
end

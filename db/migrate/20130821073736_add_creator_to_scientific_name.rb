class AddCreatorToScientificName < ActiveRecord::Migration[4.2]
  def change
    add_column :scientific_names, :creator_id, :integer
  end
end

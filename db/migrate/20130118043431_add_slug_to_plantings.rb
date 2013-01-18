class AddSlugToPlantings < ActiveRecord::Migration
  def change
    add_column :plantings, :slug, :string
    add_index :plantings, :slug, unique: true
  end
end

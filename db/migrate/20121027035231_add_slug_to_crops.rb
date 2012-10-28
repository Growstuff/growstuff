class AddSlugToCrops < ActiveRecord::Migration
  def change
    add_column :crops, :slug, :string
    add_index :crops, :slug, unique: true
  end
end

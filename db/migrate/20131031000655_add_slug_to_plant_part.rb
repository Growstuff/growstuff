class AddSlugToPlantPart < ActiveRecord::Migration
  def change
    add_column :plant_parts, :slug, :string
  end
end

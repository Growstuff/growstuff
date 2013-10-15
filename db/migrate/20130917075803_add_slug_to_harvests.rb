class AddSlugToHarvests < ActiveRecord::Migration
  def change
    add_column :harvests, :slug, :string
  end
end

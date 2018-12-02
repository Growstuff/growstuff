class AddSlugToContainers < ActiveRecord::Migration
  def change
    add_column :containers, :slug, :string
    add_index :containers, :slug, unique: true
  end
end

class AddSlugToUpdates < ActiveRecord::Migration
  def change
    add_column :updates, :slug, :string
    add_index :updates, :slug, unique: true
  end
end

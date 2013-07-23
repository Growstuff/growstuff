class AddSlugToSeed < ActiveRecord::Migration
  def change
    add_column :seeds, :slug, :string
    add_index :seeds, :slug, unique: true
  end
end

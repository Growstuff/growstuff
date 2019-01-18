class CreateContainers < ActiveRecord::Migration[4.2]
  def change
    create_table :containers do |t|
      t.string :description
      t.timestamps null: false
    end
    create_table :plots do |t|
      t.references :garden, foreign_key: true
      t.references :container, foreign_key: true
      t.timestamps null: false
    end
    add_column :containers, :slug, :string
    add_index :containers, :slug, unique: true
  end
end

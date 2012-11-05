class CreateGardens < ActiveRecord::Migration
  def change
    create_table :gardens do |t|
      t.string  :name, :null => false
      t.integer :user_id, :null => false
      t.string  :slug, :null => false

      t.timestamps
    end

    add_index :gardens, :user_id
    add_index :gardens, :slug, unique: true
  end
end

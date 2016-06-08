class CreateRoles < ActiveRecord::Migration
  def change
    create_table :roles do |t|
      t.string :name, null: false
      t.text :description

      t.timestamps null: true
    end
  end
end

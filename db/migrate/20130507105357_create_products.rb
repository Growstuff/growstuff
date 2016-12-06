class CreateProducts < ActiveRecord::Migration
  def change
    create_table :products do |t|
      t.string :name, null: false
      t.string :description, null: false
      t.decimal :min_price, null: false

      t.timestamps null: true
    end
  end
end

class CreateNotifications < ActiveRecord::Migration
  def change
    create_table :notifications do |t|
      t.integer :from_id
      t.integer :to_id, null: false
      t.string :subject
      t.text :body
      t.boolean :read
      t.integer :post_id

      t.timestamps null: true
    end
  end
end

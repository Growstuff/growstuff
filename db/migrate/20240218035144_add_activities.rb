# frozen_string_literal: true

class AddActivities < ActiveRecord::Migration[7.1]
  def change
    create_table :activities do |t|
      t.string :category
      t.string :name
      t.string :description
      t.string :due_date
      t.boolean :finished
      t.references :owner
      t.references :garden
      t.references :planting
      t.timestamps
    end
  end
end

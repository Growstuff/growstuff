# frozen_string_literal: true

class CreateRoles < ActiveRecord::Migration[4.2]
  def change
    create_table :roles do |t|
      t.string :name, null: false
      t.text :description

      t.timestamps null: true
    end
  end
end

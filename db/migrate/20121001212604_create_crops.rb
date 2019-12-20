# frozen_string_literal: true

class CreateCrops < ActiveRecord::Migration[4.2]
  def change
    create_table :crops do |t|
      t.string :system_name
      t.string :en_wikipedia_url
      t.timestamps null: true
    end
  end
end

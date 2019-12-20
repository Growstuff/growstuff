# frozen_string_literal: true

class CreateGardenTypes < ActiveRecord::Migration[5.2]
  def change
    create_table :garden_types do |t|
      t.text :name, null: false, unique: true
      t.text :slug, null: false, unique: true
      t.timestamps null: false
    end
    add_column :gardens, :garden_type_id, :integer
    add_index :gardens, :garden_type_id
    ['organic', 'conventional', 'container', 'vertical', 'greenhouse', 'rooftop', 'no-dig', 'raised bed',
     'wicking bed', 'permaculture', 'hydroponic', 'aquaponic', 'orchard', 'food forest',
     'biodynamic'].each do |name|
      say "Creating #{name}"
      GardenType.create! name: name
    end
  end
end

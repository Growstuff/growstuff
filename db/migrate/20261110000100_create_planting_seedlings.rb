# frozen_string_literal: true

# What a member knows about a planting they bought or were given as a seedling: where it came from and what its label said.
class CreatePlantingSeedlings < ActiveRecord::Migration[8.1]
  def change
    create_table :planting_seedlings do |t|
      t.references :planting, null: false, index: { unique: true }, foreign_key: { on_delete: :cascade }
      t.string :source, comment: 'shop, nursery, market, gift or unknown.'
      t.string :supplier, comment: 'Who sold or gave it, as the member put it.'
      t.text :label_text, comment: 'What the label or tag said.'
      t.timestamps
    end
  end
end

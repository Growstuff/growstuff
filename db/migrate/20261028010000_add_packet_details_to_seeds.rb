# frozen_string_literal: true

# What a seed packet prints, that a seed had nowhere to keep: the variety (a
# crop is "tomato", a variety is "Island Bay Italian"), the supplier's batch
# number, and how far apart to plant the rows.
class AddPacketDetailsToSeeds < ActiveRecord::Migration[8.1]
  def change
    change_table :seeds, bulk: true do |t|
      t.string :variety
      t.string :batch_number
      t.integer :row_spacing, comment: 'Centimetres between rows, as printed on the packet.'
    end
  end
end

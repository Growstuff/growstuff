# frozen_string_literal: true

class AddBrandAndBarcodeToSeeds < ActiveRecord::Migration[8.1]
  def change
    change_table :seeds, bulk: true do |t|
      t.string :brand
      t.string :barcode
    end
  end
end

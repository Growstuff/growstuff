# frozen_string_literal: true

class CreateCropCompanions < ActiveRecord::Migration[5.2]
  def change
    create_table :crop_companions do |t|
      t.integer "crop_a_id", null: false
      t.integer "crop_b_id", null: false
      t.timestamps null: false
    end
  end
end

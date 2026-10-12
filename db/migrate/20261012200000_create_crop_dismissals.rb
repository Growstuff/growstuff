# frozen_string_literal: true

# Crops a member has said are not for them, so the home page stops suggesting them.
class CreateCropDismissals < ActiveRecord::Migration[8.1]
  def change
    create_table :crop_dismissals do |t|
      t.references :member, null: false, foreign_key: true, index: false
      t.references :crop, null: false, foreign_key: true
      t.timestamps
    end
    add_index :crop_dismissals, %i[member_id crop_id], unique: true
  end
end

# frozen_string_literal: true

# A member's access to upload photos to the Growstuff photo library: their
# request, and an admin's decision on it.
class CreatePhotoLibraryAccesses < ActiveRecord::Migration[8.1]
  def change
    create_table :photo_library_accesses do |t|
      t.references :member, null: false, foreign_key: true, index: { unique: true }
      t.string :status, null: false, default: 'requested'
      t.text :request_message
      t.references :decided_by, foreign_key: { to_table: :members, on_delete: :nullify }
      t.datetime :decided_at
      t.text :note
      t.timestamps
    end
    add_index :photo_library_accesses, :status
  end
end

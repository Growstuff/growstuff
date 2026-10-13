# frozen_string_literal: true

# Members a member has said they are not interested in following, so the
# friends and neighbours page stops suggesting them.
class CreateMemberDismissals < ActiveRecord::Migration[8.1]
  def change
    create_table :member_dismissals do |t|
      t.references :member, null: false, foreign_key: true, index: false
      t.references :dismissed, null: false, foreign_key: { to_table: :members }
      t.timestamps
    end
    add_index :member_dismissals, %i(member_id dismissed_id), unique: true
  end
end

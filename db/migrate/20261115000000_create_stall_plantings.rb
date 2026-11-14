# frozen_string_literal: true

# A planting on a member's stall: on offer, with nobody to give it to yet, or given away, and who to: an email address, or a
# Fediverse or Bluesky handle, which may not belong to a member yet. Whoever signs in as that address or handle can claim it
# into one of their gardens.
#
# plantings.given_away_at is set while it is with the giver and nobody has claimed it. It is not finished, so it counts
# for nothing in the crop's medians, but it is no longer an active planting. Claiming clears it.
class CreateStallPlantings < ActiveRecord::Migration[8.1]
  def change
    add_column :plantings, :given_away_at, :datetime,
               comment: 'When the owner gave it away, until someone claims it. Not finished: it stays out of the crop medians.'

    create_table :stall_plantings do |t|
      t.references :stall, null: false, foreign_key: true
      t.references :planting, null: false, foreign_key: true
      t.string :recipient_kind, comment: 'email, mastodon or bluesky. Blank while it is only on offer.'
      t.string :recipient, comment: 'The address or handle it was given to, lower case. Blank while it is only on offer.'
      t.datetime :given_away_at, comment: 'Blank while it is only on offer.'
      t.references :claimed_by, foreign_key: { to_table: :members }
      t.datetime :claimed_at
      t.timestamps
    end
    # One live record per planting; once claimed, its new owner can give it on from their own stall.
    add_index :stall_plantings, :planting_id, unique: true, where: 'claimed_at IS NULL', name: 'index_stall_plantings_on_unclaimed_planting'
    add_index :stall_plantings, %i(recipient_kind recipient)
  end
end

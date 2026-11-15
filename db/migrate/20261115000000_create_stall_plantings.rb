# frozen_string_literal: true

# A planting on a member's stall: on offer, with nobody to give it to yet, or given away, and who to: a member picked from
# Growstuff, or a name the giver uses, with the email address or Fediverse or Bluesky handle they sign in with if known.
# Whoever it was given to, or signs in as that address or handle, can claim it into one of their gardens.
#
# plantings.given_away_at is set while it is with the giver and nobody has accepted it into a garden. It is not finished, so it counts
# for nothing in the crop's medians, but it is no longer an active planting. Claiming clears it.
class CreateStallPlantings < ActiveRecord::Migration[8.1]
  def change
    add_column :plantings, :given_away_at, :datetime,
               comment: 'When the owner gave it away, until someone claims it. Not finished: it stays out of the crop medians.'

    create_table :stall_plantings do |t|
      t.references :stall, null: false, foreign_key: true
      t.references :planting, null: false, foreign_key: true
      t.string :recipient_kind, comment: 'email, mastodon or bluesky: how they sign in, when the giver knows.'
      t.string :recipient, comment: 'The address or handle they sign in with, lower case, when the giver knows it.'
      t.datetime :given_away_at, comment: 'Blank while it is only on offer.'
      t.references :recipient_member, foreign_key: { to_table: :members }, comment: 'A member it was given to, picked from Growstuff.'
      t.string :recipient_name, comment: 'Whatever the giver calls someone who is not a member, or has not been found.'
      t.references :accepted_by, foreign_key: { to_table: :members }
      t.datetime :accepted_at
      t.timestamps
    end
    # One live record per planting; once accepted, its new owner can give it on from their own stall.
    add_index :stall_plantings, :planting_id, unique: true, where: 'accepted_at IS NULL', name: 'index_stall_plantings_on_unaccepted_planting'
    add_index :stall_plantings, %i(recipient_kind recipient)
  end
end

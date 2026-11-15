# frozen_string_literal: true

# Handing a packet of seed or a seedling over takes both people: the giver says they gave it, the receiver says they got it.
# When both have, the original stays with the giver, marked as given away, and a new record is born for the receiver that
# knows where it came from, as a transplant keeps where a planting was.
class AddHandoverToClaimsPlantingsAndSeeds < ActiveRecord::Migration[8.1]
  def change
    change_table :claims, bulk: true do |t|
      t.datetime :given_at, comment: 'When the giver said they handed it over.'
      t.datetime :received_at, comment: 'When the claimer said they collected it.'
      t.datetime :completed_at, comment: 'When both had said so, and the new record was made for the claimer.'
      t.references :receiving_garden, foreign_key: { to_table: :gardens }, comment: 'Where the claimer will put a seedling.'
    end

    add_column :seeds, :given_away_at, :datetime, comment: 'When the owner gave it away. It stays as the record of it, out of their library.'
    add_reference :seeds, :received_from, foreign_key: { to_table: :seeds }, comment: 'The packet this one was made from, when given by someone.'
    add_reference :plantings, :received_from, foreign_key: { to_table: :plantings },
                                              comment: 'The planting this one was made from, when given by someone.'
  end
end

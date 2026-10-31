# frozen_string_literal: true

# What a seed packet says about sowing it: the months to sow in (several allowed),
# how to sow it, and how long it takes to come up. Germination is a range of days,
# as maturity is.
class AddSowingToSeeds < ActiveRecord::Migration[8.1]
  def change
    change_table :seeds, bulk: true do |t|
      t.integer :sow_months, array: true, default: [], null: false,
                             comment: 'The months, 1 to 12, the packet says to sow in. Empty when it says nothing.'
      t.text :how_to_sow, comment: 'How the packet says to sow it, in its words.'
      t.integer :germination_days_min
      t.integer :germination_days_max
    end
  end
end

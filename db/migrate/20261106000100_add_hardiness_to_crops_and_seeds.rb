# frozen_string_literal: true

# How much frost a plant takes: tender, half_hardy or hardy. A seed packet says it, in the grower's entry, and the
# crop keeps what most of its packets say. A crop wrangler can set it by hand.
class AddHardinessToCropsAndSeeds < ActiveRecord::Migration[8.1]
  def change
    add_column :seeds, :hardiness, :text, default: 'unknown', comment: 'What the packet says: tender, half_hardy, hardy or unknown.'

    change_table :crops, bulk: true do |t|
      t.string :hardiness, default: 'unknown', null: false, comment: 'tender, half_hardy, hardy or unknown.'
      t.string :hardiness_source, comment: 'Where hardiness came from: seed_packets or manual. A manual one is not overwritten.'
    end
  end
end

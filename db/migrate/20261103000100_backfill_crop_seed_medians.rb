# frozen_string_literal: true

# Works out the medians from seed packets for the crops that already have packets, so
# their pages show them without waiting for a packet to be saved.
class BackfillCropSeedMedians < ActiveRecord::Migration[8.1]
  def up
    Crop.reset_column_information
    with_seeds = Crop.where(id: Seed.unscoped.select(:crop_id))
    with_seeds.or(Crop.where(id: with_seeds.select(:parent_id))).find_each(&:update_seed_medians)
  end

  def down
    # The medians stay: they are only figures worked out from the packets.
  end
end

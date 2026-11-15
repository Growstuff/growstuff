# frozen_string_literal: true

# Works out hardiness for every crop from its seed packets, so pages show it without waiting for a packet.
class BackfillCropHardiness < ActiveRecord::Migration[8.1]
  def up
    Crop.reset_column_information
    Crop.update_all_hardiness
  end

  def down
    # The values stay: they are only worked out from the packets.
  end
end

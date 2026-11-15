# frozen_string_literal: true

# A friend can ask for a seedling on offer as they claim a packet of seed, so a claim is for one or the other.
class AddStallPlantingToClaims < ActiveRecord::Migration[8.1]
  def change
    change_column_null :claims, :stall_seed_id, true
    add_reference :claims, :stall_planting, foreign_key: true, index: { unique: true }
  end
end

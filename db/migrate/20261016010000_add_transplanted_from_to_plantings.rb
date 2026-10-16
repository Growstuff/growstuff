# frozen_string_literal: true

# Where a planting was transplanted from, so a batch of seedlings in the nursery
# can be traced to the plantings it became.
class AddTransplantedFromToPlantings < ActiveRecord::Migration[8.1]
  def change
    add_column :plantings, :transplanted_from_id, :integer
    add_index :plantings, :transplanted_from_id
  end
end

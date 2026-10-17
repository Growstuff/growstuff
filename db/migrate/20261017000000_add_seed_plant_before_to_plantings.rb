# frozen_string_literal: true

# The plant-before date of the seed packet a planting was sown from, as it was
# at the time, so we can say it was sown from expired seeds even if the packet
# is later edited or deleted.
class AddSeedPlantBeforeToPlantings < ActiveRecord::Migration[8.1]
  def change
    add_column :plantings, :seed_plant_before, :date
  end
end

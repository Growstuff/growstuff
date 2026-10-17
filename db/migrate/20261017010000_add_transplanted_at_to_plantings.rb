# frozen_string_literal: true

# The day a planting was transplanted into its garden, as distinct from the day
# it was sown (planted_at).
class AddTransplantedAtToPlantings < ActiveRecord::Migration[8.1]
  def change
    add_column :plantings, :transplanted_at, :date
  end
end

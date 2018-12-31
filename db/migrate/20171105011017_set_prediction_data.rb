class SetPredictionData < ActiveRecord::Migration[4.2]
  def up
    say "Updating all plantings time to first harvest"
    Planting.all.each(&:update_harvest_days!)
    say "Updating crop median time to first harvest, and lifespan"
    Crop.all.each do |crop|
      crop.update_lifespan_medians
      crop.update_harvest_medians
    end
  end

  def down; end
end

class AllThePredictions < ActiveRecord::Migration
  def change
    # add_column :crops, :perennial, :boolean, default: false
    # add_column :crops, :median_time_to_first_harvest, :interval
    # add_column :crops, :median_time_to_last_harvest, :interval
    # add_column :crops, :median_time_to_finished, :interval

    add_column :plantings, :harvest_predicted_at, :datetime
    add_column :plantings, :harvested_at, :datetime
    # add_column :plantings, :failed_at, :datetime

    # add_column :plantings, :finish_predicted_at, :datetime
  end
end

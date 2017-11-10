class AllThePredictions < ActiveRecord::Migration
  def change
    add_column :crops, :perennial, :boolean, default: false

    # time from planted, to finished
    add_column :plantings, :lifespan, :integer

    # how old was planting at first harvest
    add_column :plantings, :days_to_first_harvest, :integer
    add_column :plantings, :days_to_last_harvest, :integer

    # Keep the median values for the crop
    add_column :crops, :median_lifespan, :integer
    add_column :crops, :median_days_to_first_harvest, :integer
    add_column :crops, :median_days_to_last_harvest, :integer

    remove_column :plantings, :days_before_maturity, :integer

    create_table :median_functions do |t|
    end
  end
end

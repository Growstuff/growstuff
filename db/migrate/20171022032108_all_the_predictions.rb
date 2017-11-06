class AllThePredictions < ActiveRecord::Migration
  def change
    add_column :crops, :perennial, :boolean, default: false

    # time from planted, to finished
    add_column :plantings, :lifespan, :integer

    # how old was planting at first harvest
    add_column :plantings, :first_harvest, :integer
    add_column :plantings, :last_harvest, :integer

    # Keep the median values for the crop
    add_column :crops, :median_lifespan, :integer
    add_column :crops, :median_first_harvest, :integer
    add_column :crops, :median_last_harvest, :integer

    create_table :median_functions do |t|
    end
  end
end

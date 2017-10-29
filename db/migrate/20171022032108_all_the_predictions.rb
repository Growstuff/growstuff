class AllThePredictions < ActiveRecord::Migration
  def change
    add_column :crops, :perennial, :boolean, default: false

    add_column :plantings, :lifespan, :integer
    add_column :crops, :median_lifespan, :integer

    create_table :median_functions do |t|
    end
  end
end

class GardenLayout < ActiveRecord::Migration[5.2]
  def change
    add_column(:gardens, :layout, :json)
  end
end

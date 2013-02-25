class AddGeoToMembers < ActiveRecord::Migration
  def change
    add_column :members, :location, :string
    add_column :members, :latitude, :float
    add_column :members, :longitude, :float
  end
end

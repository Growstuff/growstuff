# frozen_string_literal: true

class AddGeoToMembers < ActiveRecord::Migration[4.2]
  def change
    add_column :members, :location, :string
    add_column :members, :latitude, :float
    add_column :members, :longitude, :float
  end
end

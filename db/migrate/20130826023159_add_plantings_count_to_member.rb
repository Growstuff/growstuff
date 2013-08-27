class AddPlantingsCountToMember < ActiveRecord::Migration
  def change
    add_column :members, :plantings_count, :integer
  end
end

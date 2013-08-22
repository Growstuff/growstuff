class AddCreatorToCrops < ActiveRecord::Migration
  def change
    add_column :crops, :creator_id, :integer
  end
end

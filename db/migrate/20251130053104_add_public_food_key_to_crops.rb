class AddPublicFoodKeyToCrops < ActiveRecord::Migration[5.2]
  def change
    add_column :crops, :public_food_key, :string
  end
end

# frozen_string_literal: true

class AddCreatorToCrops < ActiveRecord::Migration[4.2]
  def change
    add_column :crops, :creator_id, :integer
  end
end

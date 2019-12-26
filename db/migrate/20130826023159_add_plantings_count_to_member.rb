# frozen_string_literal: true

class AddPlantingsCountToMember < ActiveRecord::Migration[4.2]
  def change
    add_column :members, :plantings_count, :integer
  end
end

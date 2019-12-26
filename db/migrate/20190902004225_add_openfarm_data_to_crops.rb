# frozen_string_literal: true

class AddOpenfarmDataToCrops < ActiveRecord::Migration[5.2]
  def change
    add_column :crops, :openfarm_data, :jsonb
  end
end

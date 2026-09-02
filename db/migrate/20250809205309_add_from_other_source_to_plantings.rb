# frozen_string_literal: true

class AddFromOtherSourceToPlantings < ActiveRecord::Migration[7.1]
  def change
    add_column :plantings, :from_other_source, :boolean
  end
end

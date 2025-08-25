# frozen_string_literal: true

class AddFailedToPlantings < ActiveRecord::Migration[6.0]
  def change
    add_column :plantings, :failed, :boolean, default: false, null: false
  end
end

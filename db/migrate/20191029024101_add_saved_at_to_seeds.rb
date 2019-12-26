# frozen_string_literal: true

class AddSavedAtToSeeds < ActiveRecord::Migration[5.2]
  def change
    add_column :seeds, :saved_at, :date
  end
end

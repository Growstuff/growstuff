# frozen_string_literal: true

class ChangeHarvestNotesToDescription < ActiveRecord::Migration[4.2]
  def change
    rename_column :harvests, :notes, :description
  end
end

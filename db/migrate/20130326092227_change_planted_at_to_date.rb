# frozen_string_literal: true

class ChangePlantedAtToDate < ActiveRecord::Migration[4.2]
  def change
    change_column :plantings, :planted_at, :date
  end
end

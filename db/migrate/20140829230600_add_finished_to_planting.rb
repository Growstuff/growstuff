# frozen_string_literal: true

class AddFinishedToPlanting < ActiveRecord::Migration[4.2]
  def change
    add_column :plantings, :finished, :boolean, default: false
    add_column :plantings, :finished_at, :date
  end
end

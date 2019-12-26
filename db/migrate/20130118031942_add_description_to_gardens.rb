# frozen_string_literal: true

class AddDescriptionToGardens < ActiveRecord::Migration[4.2]
  def change
    add_column :gardens, :description, :text
  end
end

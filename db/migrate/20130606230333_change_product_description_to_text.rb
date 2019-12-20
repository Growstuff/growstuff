# frozen_string_literal: true

class ChangeProductDescriptionToText < ActiveRecord::Migration[4.2]
  def up
    change_column :products, :description, :text
  end

  def down
    change_column :products, :description, :string
  end
end

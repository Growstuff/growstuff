# frozen_string_literal: true

class AddFromOtherSourceToSeeds < ActiveRecord::Migration[7.1]
  def change
    add_column :seeds, :from_other_source, :boolean
  end
end

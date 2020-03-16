# frozen_string_literal: true

class AddSunninessToPlanting < ActiveRecord::Migration[4.2]
  def change
    add_column :plantings, :sunniness, :string
  end
end

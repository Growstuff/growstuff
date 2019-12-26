# frozen_string_literal: true

class AddPropertiesToSeeds < ActiveRecord::Migration[4.2]
  def change
    add_column :seeds, :days_until_maturity_min, :integer
    add_column :seeds, :days_until_maturity_max, :integer
    add_column :seeds, :organic, :text, default: 'unknown'
    add_column :seeds, :gmo, :text, default: 'unknown'
    add_column :seeds, :heirloom, :text, default: 'unknown'
  end
end

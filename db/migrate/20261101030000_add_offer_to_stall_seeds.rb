# frozen_string_literal: true

class AddOfferToStallSeeds < ActiveRecord::Migration[8.1]
  def change
    add_column :stall_seeds, :offer, :string, default: 'free', null: false
  end
end

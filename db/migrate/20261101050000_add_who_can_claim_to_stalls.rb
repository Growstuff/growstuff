# frozen_string_literal: true

class AddWhoCanClaimToStalls < ActiveRecord::Migration[8.1]
  def change
    add_column :stalls, :claim_area, :string, default: 'region', null: false
    add_column :stalls, :postage, :boolean, default: false, null: false
  end
end

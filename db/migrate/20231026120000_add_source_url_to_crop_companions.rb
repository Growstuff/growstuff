# frozen_string_literal: true

class AddSourceUrlToCropCompanions < ActiveRecord::Migration[6.1]
  def change
    add_column :crop_companions, :source_url, :string
  end
end

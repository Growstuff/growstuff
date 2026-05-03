# frozen_string_literal: true

class AddDescriptionToCrops < ActiveRecord::Migration[7.2]
  # Temporary model to avoid validation issues
  class Crop < ApplicationRecord
  end

  def up
    add_column :crops, :description, :text

    # Ensure the new column is available to the temporary model
    Crop.reset_column_information

    Crop.find_each do |crop|
      next if crop.openfarm_data.blank?

      description = crop.openfarm_data.dig('attributes', 'description')
      crop.update_column(:description, description) if description.present?
    end
  end

  def down
    remove_column :crops, :description
  end
end

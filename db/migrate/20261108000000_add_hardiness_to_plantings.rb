# frozen_string_literal: true

# How much frost this planting takes, when the grower knows. Unknown means it goes by its seed, then its crop.
class AddHardinessToPlantings < ActiveRecord::Migration[8.1]
  def change
    add_column :plantings, :hardiness, :text, default: 'unknown', null: false,
                                              comment: 'tender, half_hardy, hardy or unknown. Unknown goes by the seed, then the crop.'
  end
end

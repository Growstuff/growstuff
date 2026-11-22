# frozen_string_literal: true

# Whether a plant of the crop is harvested once, like a lettuce, or keeps giving harvests,
# like a tomato. Empty when we don't know.
class AddHarvestStyleToCrops < ActiveRecord::Migration[8.1]
  def change
    add_column :crops, :harvest_style, :string,
               comment: "'single' when the whole plant is harvested once, 'repeated' when it keeps producing. Empty when unknown."
  end
end

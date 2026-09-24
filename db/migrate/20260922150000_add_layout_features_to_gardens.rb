# frozen_string_literal: true

# Things on a garden's layout that aren't plants: stepping stones, labels and
# rows. A list of small hashes, each with a kind and a position in grid cells,
# saved with the rest of the arrangement.
class AddLayoutFeaturesToGardens < ActiveRecord::Migration[8.1]
  def change
    add_column :gardens, :layout_features, :jsonb, default: [], null: false
  end
end

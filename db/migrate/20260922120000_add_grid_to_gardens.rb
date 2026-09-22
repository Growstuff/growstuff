# frozen_string_literal: true

# The size of the bed's layout grid, in cells, which the garden's owner sets on
# the layout page. Plantings are placed against these dimensions.
class AddGridToGardens < ActiveRecord::Migration[8.1]
  def change
    add_column :gardens, :grid_columns, :integer, default: 10, null: false
    add_column :gardens, :grid_rows, :integer, default: 10, null: false
  end
end

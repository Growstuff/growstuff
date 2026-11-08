# frozen_string_literal: true

# Whether a garden keeps its plants safe from frost (indoors, a greenhouse or a heated bench), so the frost section of a
# planting doesn't count the days it spent there. A nursery starts as safe, and any other garden as not.
class AddFrostSafeToGardens < ActiveRecord::Migration[8.1]
  def change
    add_column :gardens, :frost_safe, :boolean, default: false, null: false,
                                                comment: 'Safe from frost: indoors, a greenhouse, a heated bench. A nursery starts true.'
    reversible do |direction|
      direction.up { execute 'UPDATE gardens SET frost_safe = TRUE WHERE nursery' }
    end
  end
end

# frozen_string_literal: true

# Whether a nursery keeps its seedlings safe from frost (indoors, a greenhouse or a heated bench), so the frost
# section of a planting doesn't count the days it spent there. Most do, so it starts as true.
class AddFrostSafeToGardens < ActiveRecord::Migration[8.1]
  def change
    add_column :gardens, :frost_safe, :boolean, default: true, null: false,
                                                comment: 'A nursery that keeps seedlings safe from frost. Not used for other gardens.'
  end
end

# frozen_string_literal: true

# When a garden's layout was last saved, so that the friends and neighbours
# page can say who has been rearranging their beds.
class AddLayoutSavedAtToGardens < ActiveRecord::Migration[8.1]
  def change
    add_column :gardens, :layout_saved_at, :datetime
  end
end

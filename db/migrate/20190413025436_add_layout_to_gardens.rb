class AddLayoutToGardens < ActiveRecord::Migration[5.2]
  def change
    add_column :gardens, :layout, :jsonb
  end
end

# frozen_string_literal: true

# A member's nursery is the garden where they raise seedlings before planting
# them out. Each member has at most one.
class AddNurseryToGardens < ActiveRecord::Migration[8.1]
  def change
    add_column :gardens, :nursery, :boolean, default: false, null: false
    add_index :gardens, :owner_id, unique: true, where: 'nursery', name: 'index_gardens_on_owner_id_where_nursery'
  end
end

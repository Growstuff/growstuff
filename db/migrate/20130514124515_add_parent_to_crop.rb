# frozen_string_literal: true

class AddParentToCrop < ActiveRecord::Migration[4.2]
  def change
    add_column :crops, :parent_id, :integer
  end
end

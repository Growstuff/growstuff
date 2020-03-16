# frozen_string_literal: true

class AddCompletedToOrder < ActiveRecord::Migration[4.2]
  def change
    add_column :orders, :completed_at, :datetime
  end
end

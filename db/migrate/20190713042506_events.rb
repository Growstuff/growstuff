class Events < ActiveRecord::Migration[5.2]
  def change
    add_column :notifications, :should_send_email, :boolean
    add_column :notifications, :item_id, :integer
    add_column :notifications, :item_type, :text
    remove_column :notifications, :post_id, :integer
  end
end

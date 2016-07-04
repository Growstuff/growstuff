class CreateOrders < ActiveRecord::Migration
  def change
    create_table :orders do |t|
      t.string :member_id, null: false

      t.timestamps null: true
    end
  end
end

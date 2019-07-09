class CreateTrades < ActiveRecord::Migration[5.2]
  def change
    create_table :trades do |t|
      t.references :seed, index: true, foreign_key: true
      t.references :requested_by, index: true, foreign_key: { to_table: :members }
      t.boolean :accepted
      t.text :message
      t.text :address_for_delivery
      t.text :rejection_reason
      t.timestamps
    end
  end
end

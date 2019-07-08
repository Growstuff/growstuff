class CreateTrades < ActiveRecord::Migration[5.2]
  def change
    create_table :trades do |t|
      t.references :seed, index: true, foreign_key: true
      t.references :member, index: true, foreign_key: true
      t.boolean :accepted
      t.text :info
      t.text :rejection_reason
      t.timestamps
    end
  end
end

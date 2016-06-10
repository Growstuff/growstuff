class CreateAccountTypes < ActiveRecord::Migration
  def change
    create_table :account_types do |t|
      t.string :name
      t.boolean :is_paid
      t.boolean :is_permanent_paid

      t.timestamps null: true
    end
  end
end

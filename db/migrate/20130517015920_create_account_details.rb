class CreateAccountDetails < ActiveRecord::Migration
  def change
    create_table :account_details do |t|
      t.integer :member_id, :null => false
      t.string :account_type, :null => false, :default => 'free'
      t.datetime :paid_until

      t.timestamps
    end
  end
end

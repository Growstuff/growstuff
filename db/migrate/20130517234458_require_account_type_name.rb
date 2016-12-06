class RequireAccountTypeName < ActiveRecord::Migration
  def up
    change_column :account_types, :name, :string, null: false
  end

  def down
    change_column :account_types, :name, :string, null: true
  end
end

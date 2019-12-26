# frozen_string_literal: true

class RequireAccountTypeName < ActiveRecord::Migration[4.2]
  def up
    change_column :account_types, :name, :string, null: false
  end

  def down
    change_column :account_types, :name, :string, null: true
  end
end

# frozen_string_literal: true

class RenameAccountDetailToAccount < ActiveRecord::Migration[4.2]
  def change
    rename_table :account_details, :accounts
  end
end

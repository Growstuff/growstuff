# frozen_string_literal: true

class AddTimezoneToMembers < ActiveRecord::Migration[7.2]
  def change
    add_column :members, :timezone, :string
  end
end

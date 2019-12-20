# frozen_string_literal: true

class AddNameToAuthentications < ActiveRecord::Migration[4.2]
  def change
    add_column :authentications, :name, :string
  end
end

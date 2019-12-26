# frozen_string_literal: true

class RequireFieldsForComments < ActiveRecord::Migration[4.2]
  def up
    change_table :comments do |t|
      t.change :post_id, :integer, null: false
      t.change :author_id, :integer, null: false
      t.change :body, :text, null: false
    end
  end

  def down
    change_table :comments do |t|
      t.change :post_id, :integer, null: true
      t.change :author_id, :integer, null: true
      t.change :body, :text, null: true
    end
  end
end

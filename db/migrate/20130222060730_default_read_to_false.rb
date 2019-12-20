# frozen_string_literal: true

class DefaultReadToFalse < ActiveRecord::Migration[4.2]
  def up
    change_table :notifications do |t|
      t.change :read, :boolean, default: false
    end
  end

  def down
    change_table :notifications do |t|
      t.change :read, :boolean, default: nil
    end
  end
end

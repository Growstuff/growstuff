class DefaultReadToFalse < ActiveRecord::Migration
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

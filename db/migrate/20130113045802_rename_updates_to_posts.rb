class RenameUpdatesToPosts < ActiveRecord::Migration
  def change
    rename_table :updates, :posts
  end
end

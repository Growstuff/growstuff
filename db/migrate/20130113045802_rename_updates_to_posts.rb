class RenameUpdatesToPosts < ActiveRecord::Migration[4.2]
  def change
    rename_table :updates, :posts
  end
end

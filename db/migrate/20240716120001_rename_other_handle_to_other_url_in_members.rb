class RenameOtherHandleToOtherUrlInMembers < ActiveRecord::Migration[6.0]
  def change
    rename_column :members, :other_handle, :other_url
  end
end

class RenameGardenMemberToOwner < ActiveRecord::Migration
  def change
    rename_column :gardens, :member_id, :owner_id
  end
end

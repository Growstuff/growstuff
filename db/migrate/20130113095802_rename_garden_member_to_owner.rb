class RenameGardenMemberToOwner < ActiveRecord::Migration[4.2]
  def change
    rename_column :gardens, :member_id, :owner_id
  end
end

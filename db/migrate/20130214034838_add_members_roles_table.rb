class AddMembersRolesTable < ActiveRecord::Migration
  def change
    create_table :members_roles do |t|
      t.references :member
      t.references :role

      t.timestamps
    end
  end
end

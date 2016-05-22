class AddMembersRolesTable < ActiveRecord::Migration
  def change
    create_table :members_roles, id: false do |t|
      t.integer :member_id
      t.integer :role_id
    end
  end
end

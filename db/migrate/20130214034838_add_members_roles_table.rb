# frozen_string_literal: true

class AddMembersRolesTable < ActiveRecord::Migration[4.2]
  def change
    create_table :members_roles, id: false do |t|
      t.integer :member_id
      t.integer :role_id
    end
  end
end

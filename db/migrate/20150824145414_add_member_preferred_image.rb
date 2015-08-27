class AddMemberPreferredImage < ActiveRecord::Migration
  def change
    add_column :members, :preferred_avatar_uri, :string
  end
end

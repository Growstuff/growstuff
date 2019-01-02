class AddMemberPreferredImage < ActiveRecord::Migration[4.2]
  def change
    add_column :members, :preferred_avatar_uri, :string
  end
end

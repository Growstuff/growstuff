class AddSocialMediaToMembers < ActiveRecord::Migration[6.0]
  def change
    add_column :members, :website_url, :string
    add_column :members, :instagram_handle, :string
    add_column :members, :facebook_handle, :string
    add_column :members, :bluesky_handle, :string
    add_column :members, :other_handle, :string
  end
end

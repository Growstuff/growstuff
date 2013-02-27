class AddAboutMeToMembers < ActiveRecord::Migration
  def change
    add_column :members, :about_me, :text
  end
end

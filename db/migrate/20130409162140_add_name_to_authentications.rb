class AddNameToAuthentications < ActiveRecord::Migration
  def change
    add_column :authentications, :name, :string
  end
end

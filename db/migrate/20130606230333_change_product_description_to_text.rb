class ChangeProductDescriptionToText < ActiveRecord::Migration
  def up
    change_column :products, :description, :text
  end

  def down
    change_column :products, :description, :string
  end
end

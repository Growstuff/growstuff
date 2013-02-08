class RequireFieldsForComments < ActiveRecord::Migration
  def up
    change_table :comments do |t|
      t.change :post_id, :string, :null => false
      t.change :author_id, :string, :null => false
      t.change :body, :string, :null => false
    end
  end

  def down
    change_table :comments do |t|
      t.change :post_id, :string, :null => true
      t.change :author_id, :string, :null => true
      t.change :body, :string, :null => true
    end
  end
end

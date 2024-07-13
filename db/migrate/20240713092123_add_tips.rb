class AddTips < ActiveRecord::Migration[7.1]
  def change
    rename_column :comments, :post_id, :commentable_id
    add_column :comments, :commentable_type, :string
    rename_column :comments, :body, :comment
    add_column :comments, :title, :string, limit: 50, default: ''
    add_column :comments, :role, :string, default: 'comments'
    add_index :comments, %i(commentable_type commentable_id)

    Comment.update_columns(commentable_type: "Post")
  end
end

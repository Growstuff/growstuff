class AddCommentableToComments < ActiveRecord::Migration[6.0]
  def up
    add_column :comments, :commentable_id, :integer
    add_column :comments, :commentable_type, :string
    add_index :comments, [:commentable_type, :commentable_id]

    # Data migration
    execute <<-SQL
      UPDATE comments
      SET commentable_id = post_id,
          commentable_type = 'Post'
      WHERE post_id IS NOT NULL;
    SQL

    remove_column :comments, :post_id
  end

  def down
    add_column :comments, :post_id, :integer

    # Data migration back
    execute <<-SQL
      UPDATE comments
      SET post_id = commentable_id
      WHERE commentable_type = 'Post';
    SQL

    remove_index :comments, [:commentable_type, :commentable_id]
    remove_column :comments, :commentable_type
    remove_column :comments, :commentable_id
  end
end

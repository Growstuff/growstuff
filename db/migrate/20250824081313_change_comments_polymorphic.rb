class ChangeCommentsPolymorphic < ActiveRecord::Migration[7.2]
  def change
    add_column :comments, :commentable_type, :string
    rename_column :comments, :post_id, :commentable_id

    reversible do |dir|
      dir.up do
        ActiveRecord::Base.connection.execute("UPDATE comments SET commentable_type = 'Post' WHERE commentable_type IS NULL")
      end
    end
  end
end

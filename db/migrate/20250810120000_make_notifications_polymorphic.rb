class MakeNotificationsPolymorphic < ActiveRecord::Migration[6.1]
  def change
    add_column :notifications, :notifiable_type, :string
    rename_column :notifications, :post_id, :notifiable_id

    reversible do |dir|
      dir.up do
        ActiveRecord::Base.connection.execute("UPDATE notifications SET notifiable_type = 'Post' WHERE notifiable_type IS NULL")
      end
    end

    add_index :notifications, %i(notifiable_type notifiable_id)
  end
end

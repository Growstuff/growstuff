class AddStatusToActivities < ActiveRecord::Migration[8.1]
  def change
    unless column_exists?(:activities, :status)
      add_column :activities, :status, :string, default: 'planned'
      add_index :activities, :status
    end

    reversible do |dir|
      dir.up do
        execute "UPDATE activities SET status = 'done' WHERE finished = true"
      end
    end
  end
end

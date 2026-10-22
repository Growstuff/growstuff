# frozen_string_literal: true

# Activities are now called jobs. Records that point at one by class name are
# updated to match.
class RenameActivitiesToJobs < ActiveRecord::Migration[8.1]
  POLYMORPHIC = { likes: :likeable_type, comments: :commentable_type }.freeze

  def up
    rename_table :activities, :jobs
    rename_column :members, :activities_count, :jobs_count
    POLYMORPHIC.each { |table, column| execute "UPDATE #{table} SET #{column} = 'Job' WHERE #{column} = 'Activity'" }
  end

  def down
    POLYMORPHIC.each { |table, column| execute "UPDATE #{table} SET #{column} = 'Activity' WHERE #{column} = 'Job'" }
    rename_column :members, :jobs_count, :activities_count
    rename_table :jobs, :activities
  end
end

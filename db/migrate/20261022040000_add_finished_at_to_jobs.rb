# frozen_string_literal: true

# When a job was crossed off, so "jobs done this week" can be counted. Jobs
# already finished are taken to have been finished when they last changed.
class AddFinishedAtToJobs < ActiveRecord::Migration[8.1]
  def up
    add_column :jobs, :finished_at, :datetime
    execute 'UPDATE jobs SET finished_at = updated_at WHERE finished = TRUE'
  end

  def down
    remove_column :jobs, :finished_at
  end
end

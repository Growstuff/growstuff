class CreateSolidQueueTables < ActiveRecord::Migration[7.0]
  def up
    load "db/queue_schema.rb"
  end

  def down
    # Drop Solid Queue tables if needed
    drop_table :solid_queue_blocked_executions
    drop_table :solid_queue_claimed_executions
    drop_table :solid_queue_failed_executions
    drop_table :solid_queue_jobs
    drop_table :solid_queue_pauses
    drop_table :solid_queue_processes
    drop_table :solid_queue_ready_executions
    drop_table :solid_queue_recurring_executions
    drop_table :solid_queue_recurring_tasks
    drop_table :solid_queue_scheduled_executions
    drop_table :solid_queue_semaphores
  end
end

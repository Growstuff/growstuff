# frozen_string_literal: true

# What a job is for, when it is more than a note: to plant or to harvest the crop
# it is about. Ticking such a job off offers to record the planting or harvest.
class AddActionToJobs < ActiveRecord::Migration[8.1]
  def change
    add_column :jobs, :action, :string
  end
end

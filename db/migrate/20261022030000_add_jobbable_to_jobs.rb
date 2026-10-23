# frozen_string_literal: true

# A job can be about a crop, a planting or some seeds: anything jobbable. The
# planting a job was about moves into the same link.
class AddJobbableToJobs < ActiveRecord::Migration[8.1]
  def up
    add_reference :jobs, :jobbable, polymorphic: true, index: true
    execute "UPDATE jobs SET jobbable_type = 'Planting', jobbable_id = planting_id WHERE planting_id IS NOT NULL"
    remove_column :jobs, :planting_id
  end

  def down
    add_reference :jobs, :planting, index: true
    execute "UPDATE jobs SET planting_id = jobbable_id WHERE jobbable_type = 'Planting'"
    remove_reference :jobs, :jobbable, polymorphic: true
  end
end

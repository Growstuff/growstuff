# frozen_string_literal: true

# The template step a job was made from, so the same step is not suggested
# again for the same planting. Deleting a step leaves the job.
class AddCropJobStepToJobs < ActiveRecord::Migration[8.1]
  def change
    add_reference :jobs, :crop_job_step, foreign_key: { on_delete: :nullify }, null: true
  end
end

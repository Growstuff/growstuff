# frozen_string_literal: true

# "Save for later" on a suggested crop: a job to plant it, with no day, so it
# waits in the Some day group of their jobs, which is where they are sent.
class WishlistJobsController < ApplicationController
  skip_authorize_resource
  before_action :authenticate_member!

  def create
    crop = Crop.approved.find(params.require(:crop_id))
    job = Job.create!(owner: current_member, name: t('.job_name', crop: crop.name), action: 'plant', jobbable: crop, due_date: nil)
    redirect_to member_jobs_path(current_member, anchor: 'notepad-someday'), notice: t('.saved', job: job.name)
  end
end

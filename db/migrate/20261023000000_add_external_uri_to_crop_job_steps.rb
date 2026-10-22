# frozen_string_literal: true

# A page with more on how to do a step, such as a guide to staking tomatoes.
class AddExternalUriToCropJobSteps < ActiveRecord::Migration[8.1]
  def change
    add_column :crop_job_steps, :external_uri, :string
  end
end

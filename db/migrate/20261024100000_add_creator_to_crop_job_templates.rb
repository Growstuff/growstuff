# frozen_string_literal: true

# Who wrote a crop job template. Templates loaded from the seed files have none.
class AddCreatorToCropJobTemplates < ActiveRecord::Migration[8.1]
  def change
    add_reference :crop_job_templates, :creator, foreign_key: { to_table: :members }
  end
end

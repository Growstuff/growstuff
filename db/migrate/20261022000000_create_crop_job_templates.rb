# frozen_string_literal: true

# A crop's suggested jobs: a named list of steps whose dates are worked out
# from a planting, so one template fits every garden.
class CreateCropJobTemplates < ActiveRecord::Migration[8.1]
  def change
    create_table :crop_job_templates do |t|
      t.references :crop, null: false, foreign_key: true
      t.string :name, null: false
      t.string :season, null: false, default: 'any'
      t.string :status, null: false, default: 'draft'
      t.timestamps
    end

    create_table :crop_job_steps do |t|
      t.references :crop_job_template, null: false, foreign_key: true
      t.integer :position, null: false, default: 0
      t.string :name, null: false
      t.integer :offset_amount, null: false, default: 0
      t.string :offset_unit, null: false, default: 'weeks'
      t.string :direction, null: false, default: 'after'
      t.string :anchor, null: false, default: 'planting_out'
      t.string :repeat, null: false, default: 'once'
      t.timestamps
    end
  end
end

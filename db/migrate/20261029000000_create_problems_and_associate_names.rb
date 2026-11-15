# frozen_string_literal: true

class CreateProblemsAndAssociateNames < ActiveRecord::Migration[8.1]
  def change
    create_table :problems do |t|
      t.string :title, null: false
      t.text :description
      t.string :problem_type, null: false

      t.timestamps
    end

    change_column_null :scientific_names, :crop_id, true
    add_reference :scientific_names, :problem, foreign_key: true, index: true

    change_column_null :alternate_names, :crop_id, true
    change_column_null :alternate_names, :creator_id, true
    add_reference :alternate_names, :problem, foreign_key: true, index: true
  end
end

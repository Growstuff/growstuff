# frozen_string_literal: true

class CreateProblemsAndAssociateNames < ActiveRecord::Migration[8.1]
  def up
    unless table_exists?(:problems)
      create_table :problems do |t|
        t.string :title, null: false
        t.text :description
        t.string :problem_type, null: false

        t.timestamps
      end
    end

    # Make crop_id optional
    change_column_null :scientific_names, :crop_id, true
    change_column_null :alternate_names, :crop_id, true
    change_column_null :alternate_names, :creator_id, true

    # Add polymorphic columns
    add_column :scientific_names, :subject_type, :string unless column_exists?(:scientific_names, :subject_type)
    add_column :scientific_names, :subject_id, :bigint unless column_exists?(:scientific_names, :subject_id)
    add_index :scientific_names, %i(subject_type subject_id) unless index_exists?(:scientific_names, %i(subject_type subject_id))

    add_column :alternate_names, :subject_type, :string unless column_exists?(:alternate_names, :subject_type)
    add_column :alternate_names, :subject_id, :bigint unless column_exists?(:alternate_names, :subject_id)
    add_index :alternate_names, %i(subject_type subject_id) unless index_exists?(:alternate_names, %i(subject_type subject_id))

    # Data migration: populate polymorphic subject fields for existing Crop names
    execute <<~SQL
      UPDATE scientific_names
      SET subject_type = 'Crop', subject_id = crop_id
      WHERE crop_id IS NOT NULL AND subject_id IS NULL;
    SQL

    execute <<~SQL
      UPDATE alternate_names
      SET subject_type = 'Crop', subject_id = crop_id
      WHERE crop_id IS NOT NULL AND subject_id IS NULL;
    SQL
  end

  def down
    remove_index :alternate_names, %i(subject_type subject_id) if index_exists?(:alternate_names, %i(subject_type subject_id))
    remove_column :alternate_names, :subject_id if column_exists?(:alternate_names, :subject_id)
    remove_column :alternate_names, :subject_type if column_exists?(:alternate_names, :subject_type)

    remove_index :scientific_names, %i(subject_type subject_id) if index_exists?(:scientific_names, %i(subject_type subject_id))
    remove_column :scientific_names, :subject_id if column_exists?(:scientific_names, :subject_id)
    remove_column :scientific_names, :subject_type if column_exists?(:scientific_names, :subject_type)

    drop_table :problems if table_exists?(:problems)
  end
end

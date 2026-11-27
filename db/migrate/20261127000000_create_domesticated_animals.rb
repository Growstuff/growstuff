# frozen_string_literal: true

class CreateDomesticatedAnimals < ActiveRecord::Migration[8.1]
  def change
    create_table :domesticated_animals do |t|
      t.string :name, null: false
      t.string :species, null: false
      t.string :category, null: false
      t.string :description
      t.date :date_of_birth
      t.date :date_of_death
      t.string :biological_sex
      t.references :owner, null: false, foreign_key: { to_table: :members }
      t.timestamps
    end

    create_table :animal_tags do |t| # rubocop:disable Rails/CreateTableWithTimestamps -- Join table, like crop_posts.
      t.references :domesticated_animal, null: false, foreign_key: true
      t.references :taggable, polymorphic: true, null: false
      t.index %i(taggable_type taggable_id domesticated_animal_id), unique: true, name: 'index_animal_tags_unique'
    end
  end
end

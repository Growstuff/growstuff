# frozen_string_literal: true

# Which gardens a planting has been in. The planting itself has the garden it is
# in now; each row here is a garden it was in before, and for which days.
class CreatePlantingHistories < ActiveRecord::Migration[8.1]
  def change
    create_table :planting_histories do |t|
      t.references :planting, null: false, foreign_key: true
      t.references :garden, null: false
      t.date :started_on
      t.date :ended_on, null: false
      t.timestamps
    end
  end
end

class CreatePlots < ActiveRecord::Migration
  def change
    create_table :plots do |t|
      t.references :garden, foreign_key: true
      t.references :container, foreign_key: true

      t.timestamps null: false
    end
  end
end

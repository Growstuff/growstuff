class CreateCrops < ActiveRecord::Migration
  def change
    create_table :crops do |t|
      t.string :system_name
      t.string :en_wikipedia_url
      t.timestamps null: true
    end
  end
end

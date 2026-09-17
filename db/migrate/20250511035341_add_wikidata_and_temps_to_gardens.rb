class AddWikidataAndTempsToGardens < ActiveRecord::Migration[7.2]
  def change
    add_column :gardens, :location_wikidata_id, :string
    add_column :gardens, :lowest_temp_c, :float
    add_column :gardens, :highest_temp_c, :float
  end
end

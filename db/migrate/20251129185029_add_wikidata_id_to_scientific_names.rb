# frozen_string_literal: true

class AddWikidataIdToScientificNames < ActiveRecord::Migration[6.1]
  def change
    add_column :scientific_names, :wikidata_id, :string
  end
end

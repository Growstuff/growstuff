# frozen_string_literal: true

class AddGbif < ActiveRecord::Migration[7.0]
  def change
    add_column :scientific_names, :gbif_key, :int
    add_column :scientific_names, :gbif_rank, :string
    add_column :scientific_names, :gbif_status, :string
    add_column :scientific_names, :wikidata_id, :string
  end
end

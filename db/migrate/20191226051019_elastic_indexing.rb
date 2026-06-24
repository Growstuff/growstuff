# frozen_string_literal: true

class ElasticIndexing < ActiveRecord::Migration[5.2]
  def up
    say 'indexing crops'
    Crop.reindex
    say 'indexing photos'
    Photo.reindex
  end

  def down; end
end

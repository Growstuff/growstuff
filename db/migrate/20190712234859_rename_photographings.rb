# frozen_string_literal: true

class RenamePhotographings < ActiveRecord::Migration[5.2]
  def change
    rename_table :photographings, :photo_associations
  end
end

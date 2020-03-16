# frozen_string_literal: true

class AddRequestNotesToCrops < ActiveRecord::Migration[4.2]
  def change
    add_column :crops, :request_notes, :text
  end
end

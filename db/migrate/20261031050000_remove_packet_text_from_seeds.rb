# frozen_string_literal: true

# The text is on the photos now (see AddOcrToPhotos).
class RemovePacketTextFromSeeds < ActiveRecord::Migration[8.1]
  def change
    remove_column :seeds, :packet_text, :text
  end
end

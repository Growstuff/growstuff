# frozen_string_literal: true

# The text a seed packet's photos were read as, kept with the seed so it can be
# searched and read again later. Filled in by the OCR script, and not shown or
# editable by members yet.
class AddPacketTextToSeeds < ActiveRecord::Migration[8.1]
  def change
    add_column :seeds, :packet_text, :text, comment: "Text read from the packet's photos by the OCR script. Not shown to members yet."
  end
end

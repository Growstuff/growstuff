# frozen_string_literal: true

# The text a seed packet's photos were read as, kept with the seed so the member
# can see and correct it, and so it can be searched and read again later.
class AddPacketTextToSeeds < ActiveRecord::Migration[8.1]
  def change
    add_column :seeds, :packet_text, :text, comment: 'What reading the photos of the packet found, for the member to check.'
  end
end

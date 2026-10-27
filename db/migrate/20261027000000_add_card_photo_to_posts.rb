# frozen_string_literal: true

# The photo that stands for a post wherever it shows as a card.
class AddCardPhotoToPosts < ActiveRecord::Migration[8.1]
  def change
    add_reference :posts, :card_photo, foreign_key: { to_table: :photos, on_delete: :nullify }
  end
end

# frozen_string_literal: true

class AddNewsletterToMember < ActiveRecord::Migration[4.2]
  def change
    add_column :members, :newsletter, :boolean
  end
end

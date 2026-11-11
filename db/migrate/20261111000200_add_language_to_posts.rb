# frozen_string_literal: true

class AddLanguageToPosts < ActiveRecord::Migration[8.1]
  def change
    add_column :posts, :language, :string
  end
end

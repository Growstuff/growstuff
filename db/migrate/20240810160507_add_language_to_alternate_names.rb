# frozen_string_literal: true

class AddLanguageToAlternateNames < ActiveRecord::Migration[7.2]
  def change
    add_column :alternate_names, :language, :string
  end
end

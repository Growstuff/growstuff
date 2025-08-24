# frozen_string_literal: true

class SetDefaultLanguageForExistingAlternateNames < ActiveRecord::Migration[7.2]
  def up
    AlternateName.update_all(language: 'en')
  end

  def down
    AlternateName.update_all(language: nil)
  end
end

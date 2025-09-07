# frozen_string_literal: true

class SetDefaultLanguageForExistingAlternateNames < ActiveRecord::Migration[7.2]
  def up
    AlternateName.update_all(language: 'en') # rubocop:disable Rails/SkipsModelValidations
  end

  def down
    AlternateName.update_all(language: nil) # rubocop:disable Rails/SkipsModelValidations
  end
end

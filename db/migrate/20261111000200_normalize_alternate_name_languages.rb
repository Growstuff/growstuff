# frozen_string_literal: true

class NormalizeAlternateNameLanguages < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL
      UPDATE alternate_names
      SET language = LOWER(language)
      WHERE language ~ '^[A-Za-z]{2}$'
        AND language <> LOWER(language)
    SQL
  end

  def down
    raise ActiveRecord::IrreversibleMigration, 'Original language code capitalization cannot be restored'
  end
end

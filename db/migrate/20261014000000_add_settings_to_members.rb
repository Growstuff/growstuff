# frozen_string_literal: true

# Odds and ends about a member that don't earn a column of their own, such as
# when they first saw a new feature.
class AddSettingsToMembers < ActiveRecord::Migration[8.1]
  def change
    add_column :members, :settings, :jsonb, default: {}, null: false
  end
end

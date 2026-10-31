# frozen_string_literal: true

class AddSpamScoreToMembers < ActiveRecord::Migration[8.1]
  def change
    add_column :members, :spam_score, :integer, default: 0, null: false
  end
end

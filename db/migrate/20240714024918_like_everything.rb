# frozen_string_literal: true

class LikeEverything < ActiveRecord::Migration[7.1]
  def change
    change_table :activities do |t|
      t.integer :likes_count, default: 0
    end

    change_table :plantings do |t|
      t.integer :likes_count, default: 0
    end

    change_table :harvests do |t|
      t.integer :likes_count, default: 0
    end
  end
end

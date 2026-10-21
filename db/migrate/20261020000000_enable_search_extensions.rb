# frozen_string_literal: true

# Crop search runs in Postgres: pg_trgm for typo-tolerant matching.
class EnableSearchExtensions < ActiveRecord::Migration[8.1]
  def change
    enable_extension 'pg_trgm'
  end
end

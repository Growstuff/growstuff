# frozen_string_literal: true

# Crop search runs in Postgres: pg_trgm for typo-tolerant matching and
# unaccent so "jalapeno" finds "jalapeño".
class EnableSearchExtensions < ActiveRecord::Migration[8.1]
  def change
    enable_extension 'pg_trgm'
    enable_extension 'unaccent'
  end
end

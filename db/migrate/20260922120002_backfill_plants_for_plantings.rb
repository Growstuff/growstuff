# frozen_string_literal: true

# Existing plantings predate the plants table, so they have nothing to place on
# a bed's layout. This gives each one a plant per plant it says it has.
#
# Capped at the same number as Planting::MAX_PLANTS, repeated here as a literal
# so this migration keeps doing what it did today even if that constant moves.
class BackfillPlantsForPlantings < ActiveRecord::Migration[8.1]
  MAX_PLANTS = 100

  # Local models, so a later change to the real ones can't alter what this does.
  class Planting < ActiveRecord::Base; end
  class Plant < ActiveRecord::Base; end

  def up
    say_with_time 'giving every planting one plant per plant' do
      created = 0
      Planting.select(:id, :quantity).find_in_batches(batch_size: 500) do |batch|
        now = Time.current
        rows = batch.flat_map do |planting|
          count = planting.quantity.to_i.clamp(1, MAX_PLANTS)
          Array.new(count) { { planting_id: planting.id, created_at: now, updated_at: now } }
        end
        next if rows.empty?

        Plant.insert_all(rows) # rubocop:disable Rails/SkipsModelValidations
        created += rows.size
      end
      created
    end
  end

  def down
    Plant.delete_all
  end
end

# frozen_string_literal: true

class SeedUsage < ActiveRecord::Migration[4.2]
  def change
    # # seed can be all sown, meaning there is none left
    add_column(:seeds, :finished, :boolean, default: false)
    add_column(:seeds, :finished_at, :date, default: nil)

    # plantings can be grown from a seed
    add_column(:plantings, :parent_seed_id, :integer)
    add_foreign_key(:plantings, :seeds,
                    column:      :parent_seed_id,
                    primary_key: :id,
                    name:        :parent_seed,
                    on_delete:   :nullify)
    # seeds can be harvest from planting
    add_column(:seeds, :parent_planting_id, :integer)
    add_foreign_key(:seeds, :plantings,
                    column:      :parent_planting_id,
                    primary_key: :id,
                    name:        :parent_planting,
                    on_delete:   :nullify)
  end
end

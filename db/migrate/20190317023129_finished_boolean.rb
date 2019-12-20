# frozen_string_literal: true

class FinishedBoolean < ActiveRecord::Migration[5.2]
  def change
    Planting.unscoped.where('finished_at < now()').update_all(finished: true)
    Planting.unscoped.where(finished: nil).update_all(finished: false)
    change_column_null :plantings, :finished, false
    change_column_default :plantings, :finished, from: nil, to: false
  end
end

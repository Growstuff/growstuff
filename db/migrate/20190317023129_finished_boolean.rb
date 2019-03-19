class FinishedBoolean < ActiveRecord::Migration[5.2]
  def change
    Planting.where('finished_at < now()').update_all(finished: true)
    Planting.where(finished: nil).update_all(finished: false)
    change_column_null :plantings, :finished, false
    change_column_default :plantings, :finished, from: nil, to: false
  end
end

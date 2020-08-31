class RemoveMedianFunction < ActiveRecord::Migration[6.0]
  def change
    # No longer needed, after upgrading to activemedian 0.2.0
    ActiveMedian.drop_function
  end
end

class CreateMedianFunction < ActiveRecord::Migration
  def up
    ActiveMedian.create_function
  end

  def down
    ActiveMedian.drop_function
  end
end

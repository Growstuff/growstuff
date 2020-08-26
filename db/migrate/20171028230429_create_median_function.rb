# frozen_string_literal: true

class CreateMedianFunction < ActiveRecord::Migration[4.2]
  def up
    # commented out, because we upgraded the gem later and this function was removed
    # ActiveMedian.create_function
  end

  def down
    # ActiveMedian.drop_function
  end
end

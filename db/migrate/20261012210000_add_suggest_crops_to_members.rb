# frozen_string_literal: true

# Whether the home page suggests crops to sow. Members can turn it off.
class AddSuggestCropsToMembers < ActiveRecord::Migration[8.1]
  def change
    add_column :members, :suggest_crops, :boolean, default: true, null: false
  end
end

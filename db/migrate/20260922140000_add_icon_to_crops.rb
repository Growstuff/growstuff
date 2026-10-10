# frozen_string_literal: true

# Which of the app's crop icons (app/assets/images/crops) a crop is drawn
# with, by file name. Blank means it follows its parent crop.
class AddIconToCrops < ActiveRecord::Migration[8.1]
  def change
    add_column :crops, :icon, :string
  end
end

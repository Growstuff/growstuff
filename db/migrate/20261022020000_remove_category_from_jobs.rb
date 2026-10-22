# frozen_string_literal: true

# Jobs are a plain list now, so they no longer have a category.
class RemoveCategoryFromJobs < ActiveRecord::Migration[8.1]
  def change
    remove_column :jobs, :category, :string
  end
end

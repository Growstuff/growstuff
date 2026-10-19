# frozen_string_literal: true

class RemoveNewsletterFromMembers < ActiveRecord::Migration[8.1]
  def change
    remove_column :members, :newsletter, :boolean
  end
end

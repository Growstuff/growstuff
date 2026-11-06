# frozen_string_literal: true

# Someone who signs in with Bluesky may not have an email address we can use.
# NULLs don't collide in the unique index; empty strings would.
class AllowMembersWithoutEmail < ActiveRecord::Migration[8.1]
  def change
    change_column_null :members, :email, true
    change_column_default :members, :email, from: "", to: nil
  end
end

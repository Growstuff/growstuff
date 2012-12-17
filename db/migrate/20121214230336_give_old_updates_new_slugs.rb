class GiveOldUpdatesNewSlugs < ActiveRecord::Migration
  def up
    Update.find_each(&:save)
  end

  # note: this is basically impossible to reverse without removing
  # friendly_id, because friendly_id automatically updates the slug when
  # you save the object.
end

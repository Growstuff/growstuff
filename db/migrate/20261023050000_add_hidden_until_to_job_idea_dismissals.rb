# frozen_string_literal: true

# When a hidden idea may be suggested again, so it can be snoozed for a week or a
# month, or dismissed for longer.
class AddHiddenUntilToJobIdeaDismissals < ActiveRecord::Migration[8.1]
  def up
    add_column :job_idea_dismissals, :hidden_until, :datetime
    execute 'UPDATE job_idea_dismissals SET hidden_until = updated_at + INTERVAL \'1 month\''
    change_column_null :job_idea_dismissals, :hidden_until, false
  end

  def down
    remove_column :job_idea_dismissals, :hidden_until
  end
end

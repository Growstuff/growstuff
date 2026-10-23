# frozen_string_literal: true

# A suggested job a member said was not for them. The key says which idea it
# was; the idea stays hidden for a while.
class CreateJobIdeaDismissals < ActiveRecord::Migration[8.1]
  def change
    create_table :job_idea_dismissals do |t|
      t.references :member, null: false, foreign_key: true
      t.string :key, null: false
      t.timestamps
    end
    add_index :job_idea_dismissals, %i(member_id key), unique: true
  end
end

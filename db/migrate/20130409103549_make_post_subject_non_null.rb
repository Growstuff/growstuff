class MakePostSubjectNonNull < ActiveRecord::Migration[4.2]
  change_column :posts, :subject, :string, null: false
end

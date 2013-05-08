class MakePostSubjectNonNull < ActiveRecord::Migration
  change_column :posts, :subject, :string, :null => false
end

# frozen_string_literal: true

# The newsletter feature has been removed, but the column is kept in case we
# bring it back.
class CommentOnMembersNewsletter < ActiveRecord::Migration[8.1]
  COMMENT = 'From when we had a newsletter. Unused now, kept in case we bring it back.'

  def change
    change_column_comment :members, :newsletter, from: nil, to: COMMENT
  end
end

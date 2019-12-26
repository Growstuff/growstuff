# frozen_string_literal: true

class ParanoiaToDiscard < ActiveRecord::Migration[5.2]
  def change
    rename_column :members, :deleted_at, :discarded_at
  end
end

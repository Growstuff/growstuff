# frozen_string_literal: true

# A photo's part of the thing it is of: a job's "before" or "after", the "front"
# or "back" of a seed packet. Most photos have no label.
class RenameMomentToLabelOnPhotoAssociations < ActiveRecord::Migration[8.1]
  def change
    rename_column :photo_associations, :moment, :label
  end
end

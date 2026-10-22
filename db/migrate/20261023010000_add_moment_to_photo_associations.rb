# frozen_string_literal: true

# When a photo was taken, relative to the thing it is of: a job's "before" and
# "after". Most photos have no moment.
class AddMomentToPhotoAssociations < ActiveRecord::Migration[8.1]
  def change
    add_column :photo_associations, :moment, :string
  end
end

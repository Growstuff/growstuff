class AddReasonForRejectionToCrops < ActiveRecord::Migration
  def change
    add_column :crops, :reason_for_rejection, :text
  end
end

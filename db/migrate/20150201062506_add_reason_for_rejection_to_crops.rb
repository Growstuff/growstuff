# frozen_string_literal: true

class AddReasonForRejectionToCrops < ActiveRecord::Migration[4.2]
  def change
    add_column :crops, :reason_for_rejection, :text
  end
end

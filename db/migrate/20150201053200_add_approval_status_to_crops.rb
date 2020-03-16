# frozen_string_literal: true

class AddApprovalStatusToCrops < ActiveRecord::Migration[4.2]
  def change
    add_column :crops, :approval_status, :string, default: "approved"
  end
end

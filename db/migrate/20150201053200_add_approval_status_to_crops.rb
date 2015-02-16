class AddApprovalStatusToCrops < ActiveRecord::Migration
  def change
    add_column :crops, :approval_status, :string, default: "approved"
  end
end

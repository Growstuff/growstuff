class CreateGardenCollaborators < ActiveRecord::Migration[7.2]
  def change
    create_table :garden_collaborators do |t|
      t.references :member
      t.references :garden
      t.timestamps
      t.index [:member_id, :garden_id], unique: true
    end
  end
end

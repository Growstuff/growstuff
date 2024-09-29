class CreateGardenCollaborators < ActiveRecord::Migration[7.2]
  def change
    create_table :garden_collaborators do |t|
      t.timestamps
    end
  end
end

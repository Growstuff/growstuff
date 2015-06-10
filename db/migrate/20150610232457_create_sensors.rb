class CreateSensors < ActiveRecord::Migration
  def change
    create_table :sensors do |t|

      t.timestamps
    end
  end
end

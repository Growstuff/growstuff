class CreateRecordings < ActiveRecord::Migration
  def change
    create_table :recordings do |t|

      t.timestamps
    end
  end
end

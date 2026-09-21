class AddAlternateNameToPlantings < ActiveRecord::Migration[7.2]
  def change
    add_reference :plantings, :alternate_name, type: :integer, null: true, index: true,
                                               foreign_key: { on_delete: :nullify }
  end
end

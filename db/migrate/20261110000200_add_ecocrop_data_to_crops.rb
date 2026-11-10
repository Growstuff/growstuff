# frozen_string_literal: true

# The EcoCrop record a crop's growing figures come from, set by the crops:match_ecocrop tasks.
class AddEcocropDataToCrops < ActiveRecord::Migration[8.1]
  def change
    add_reference :crops, :ecocrop_data, foreign_key: { on_delete: :nullify },
                                         comment:     'The EcoCrop record for this crop, matched by scientific name.'
  end
end

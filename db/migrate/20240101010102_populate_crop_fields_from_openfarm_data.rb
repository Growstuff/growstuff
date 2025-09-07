class PopulateCropFieldsFromOpenfarmData < ActiveRecord::Migration[5.2]
  def up
    Crop.find_each do |crop|
      if crop.openfarm_data.present?
        attributes = crop.openfarm_data.fetch('attributes', {})
        crop.update_columns(
          row_spacing: attributes['row_spacing'],
          spread: attributes['spread'],
          height: attributes['height'],
          sowing_method: attributes['sowing_method'],
          sun_requirements: attributes['sun_requirements'],
          growing_degree_days: attributes['growing_degree_days']
        )
      end
    end
  end

  def down
    # This migration is not reversible.
  end
end

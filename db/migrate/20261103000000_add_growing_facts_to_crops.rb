# frozen_string_literal: true

# How to grow a crop, as a crop wrangler sets it, and what members' seed packets say
# about it, as medians kept on the crop so its page needn't work them out. The
# medians are named median_ because they are worked out from our data.
class AddGrowingFactsToCrops < ActiveRecord::Migration[8.1]
  def change
    change_table :crops, bulk: true do |t|
      t.integer :germination_days_min, comment: 'Days to germinate, at least.'
      t.integer :germination_days_max, comment: 'Days to germinate, at most.'
      t.integer :days_until_maturity_min, comment: 'Days from sowing to harvest, at least.'
      t.integer :days_until_maturity_max, comment: 'Days from sowing to harvest, at most.'
      t.integer :sow_months, array: true, default: [], null: false,
                             comment: 'Months, 1 to 12, to sow in the southern hemisphere. The northern hemisphere is six months on.'

      t.float :median_row_spacing, comment: 'Centimetres between rows, the median of the seed packets.'
      t.integer :median_sow_months, array: true, default: [], null: false,
                                    comment: 'Months, 1 to 12, to sow in the southern hemisphere, from the seed packets.'
      t.float :median_germination_days_min, comment: 'Days to germinate, the median of the packets minimums.'
      t.float :median_germination_days_max, comment: 'Days to germinate, the median of the packets maximums.'
      t.float :median_days_until_maturity_min, comment: 'Days from sowing to harvest, the median of the packets minimums.'
      t.float :median_days_until_maturity_max, comment: 'Days from sowing to harvest, the median of the packets maximums.'
    end
  end
end

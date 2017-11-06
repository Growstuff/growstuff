class CreateMedianFunction < ActiveRecord::Migration
  def up
    ActiveMedian.create_function

    say "Calculating lifespan of known finished plantings"
    Planting.where.not(planted_at: nil, finished_at: nil).each do |planting|
      planting.calculate_lifespan
      planting.save!
      if planting.crop.median_lifespan.present?
        say "#{planting.crop.name} median lifespan #{planting.crop.median_lifespan} days"
      end
    end

    say 'Calculating median lifespan of crops'
    # Crop.all.each do |crop|
    #   crop.update_medians
    #   say "#{crop.name} median lifespan #{crop.median_lifespan} days" if crop.median_lifespan.present?
    # end
  end

  def down
    ActiveMedian.drop_function
  end
end

# frozen_string_literal: true

# The crops that could be grown from a sowing in each season at the member's home, from EcoCrop's temperatures. A crop is
# left out if, in any month of its cycle, the average temperature is below the lowest it grows at, the coldest nights usually
# reach the temperature that kills it, or the days rise above the highest it grows at. Of those that survive:
#   optimal   the days' usual high, on average over its shortest cycle, is in its best range
#   tolerable the rest, which survive its longest cycle without being at their best
# A crop with no record of its own uses its parent's, and one we can't tell the cycle length of (see CropDuration) is left
# out. The most planted come first. It holds the working out and no text.
class SeasonalCrops
  LIMIT = 8

  # What is needed of a crop: its best range (best_min, best_max), the temperatures it grows at (kill_min, kill_max, either
  # can be nil), the temperature that kills it (dies_at, can be nil) and how long it takes (a CropDuration).
  Candidate = Struct.new(:crop, :best_min, :best_max, :kill_min, :kill_max, :dies_at, :duration)

  # { season name => { optimal: crops, tolerable: crops } } for each season of a SeasonalClimate that has an average.
  def self.for(climate, limit: LIMIT)
    new(climate).by_season(climate.seasons.select(&:mean), limit:)
  end

  def initialize(climate)
    @means = climate.monthly_means
    @nights = climate.monthly_nights
    @days = climate.monthly_days
  end

  def by_season(seasons, limit: LIMIT, except: [])
    seasons.to_h { |season| [season.name, sown_in(season.months, limit:, except:)] }
  end

  # { optimal: crops, tolerable: crops } for a sowing in any of the months, leaving out the crops with these ids. Without a
  # limit it gives every crop.
  def sown_in(months, limit: LIMIT, except: [])
    wanted = candidates.reject { |candidate| except.include?(candidate.crop.id) }
    optimal = wanted.select { |candidate| fits?(candidate, months, best: true) }
    tolerable = (wanted - optimal).select { |candidate| fits?(candidate, months, best: false) }
    { optimal: first_crops(optimal, limit), tolerable: first_crops(tolerable, limit) }
  end

  private

  # The crops of the candidates, all of them when there is no limit.
  def first_crops(candidates, limit)
    (limit ? candidates.first(limit) : candidates).map(&:crop)
  end

  # Every approved crop with a record and a cycle length, the most planted first. A cycle of zero days is missing data.
  def candidates
    @candidates ||= Crop.approved
      .joins('LEFT JOIN crops parents ON parents.id = crops.parent_id')
      .joins('INNER JOIN ecocrop_data ON ecocrop_data.id = COALESCE(crops.ecocrop_data_id, parents.ecocrop_data_id)')
      .where('ecocrop_data.topmn IS NOT NULL AND ecocrop_data.topmx IS NOT NULL')
      .select('crops.*, ecocrop_data.topmn AS best_min, ecocrop_data.topmx AS best_max, ecocrop_data.tmin AS kill_min, ' \
              'ecocrop_data.tmax AS kill_max, ecocrop_data.ktmp AS dies_at, ecocrop_data.gmin AS quick_days, ' \
              'ecocrop_data.gmax AS slow_days')
      .order(Arel.sql('crops.plantings_count DESC, lower(crops.name) ASC'))
      .map { |crop| candidate(crop) }
  end

  def candidate(crop)
    columns = %w(best_min best_max kill_min kill_max dies_at quick_days slow_days)
    best_min, best_max, kill_min, kill_max, dies_at, quick, slow = crop.attributes.values_at(*columns)
    duration = CropDuration.new(highs: @days, lows: @nights, degree_days: crop.growing_degree_days_figure, base: kill_min, quick:, slow:,
                                median: crop.median_days_to_first_harvest)
    Candidate.new(crop, best_min, best_max, kill_min, kill_max, dies_at, duration)
  end

  # Whether a sowing in any of the months gets through the cycle: at its best, or only surviving.
  def fits?(candidate, months, best:)
    months.any? do |start|
      taking = candidate.duration.from(start)
      next false unless taking

      needed = [((best ? taking.quick : taking.slow) / CropDuration::DAYS_IN_MONTH).ceil, 12].min
      cycle = (0...needed).map { |offset| ((start - 1 + offset) % 12) + 1 }
      cycle.all? { |month| survives?(candidate, month) } && (!best || best?(candidate, cycle))
    end
  end

  # Whether the days' usual high over the cycle is, on average, in the crop's best range. Not every month has to be: only
  # staying within what the crop grows at is needed of each. A plant does its growing in the day, so the high is compared, not
  # the average of the whole day and night, which runs well below it.
  def best?(candidate, cycle)
    high = cycle.sum { |month| @days.fetch(month) } / cycle.size
    high.between?(candidate.best_min, candidate.best_max)
  end

  # Whether the month stays within what the crop grows at and the nights stay above what kills it: the month's average
  # temperature is not below the lowest it grows at (a growing temperature, not a night's), the days do not rise above the
  # highest it grows at, and the coldest nights stay above its killing temperature. A month we hold no weather for does not.
  def survives?(candidate, month)
    mean = @means[month]
    night = @nights[month]
    day = @days[month]
    return false unless mean && night && day

    (candidate.kill_min.nil? || mean >= candidate.kill_min) && (candidate.kill_max.nil? || day <= candidate.kill_max) &&
      (candidate.dies_at.nil? || night > candidate.dies_at)
  end
end

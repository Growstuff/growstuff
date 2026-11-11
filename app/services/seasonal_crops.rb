# frozen_string_literal: true

# The crops that could be grown from a sowing in each season at the member's home, from EcoCrop's temperatures. A crop is
# left out if, in any month of its cycle, the nights usually fall below the lowest temperature it survives or the days
# rise above the highest. Of those that survive:
#   optimal   the days' usual high stays in its best range for its shortest cycle
#   tolerable the rest, which survive its longest cycle without being at their best
# A crop with no record of its own uses its parent's, and one with no cycle length is left out. The most planted come
# first. It holds the working out and no text.
class SeasonalCrops
  LIMIT = 8
  DAYS_IN_MONTH = 30.4

  # What is needed of a crop: its best range (best_min, best_max), the temperatures it survives (kill_min, kill_max, either
  # can be nil) and its shortest and longest cycle in days (quick_days, slow_days).
  Candidate = Struct.new(:crop, :best_min, :best_max, :kill_min, :kill_max, :quick_days, :slow_days)

  # { season name => { optimal: crops, tolerable: crops } } for each season of a SeasonalClimate that has an average.
  def self.for(climate, limit: LIMIT)
    new(climate).by_season(climate.seasons.select(&:mean), limit:)
  end

  def initialize(climate)
    @nights = climate.monthly_nights
    @days = climate.monthly_days
  end

  def by_season(seasons, limit: LIMIT, except: [])
    seasons.to_h { |season| [season.name, sown_in(season.months, limit:, except:)] }
  end

  # { optimal: crops, tolerable: crops } for a sowing in any of the months, leaving out the crops with these ids.
  def sown_in(months, limit: LIMIT, except: [])
    wanted = candidates.reject { |candidate| except.include?(candidate.crop.id) }
    optimal = wanted.select { |candidate| fits?(candidate, months, best: true) }
    tolerable = (wanted - optimal).select { |candidate| fits?(candidate, months, best: false) }
    { optimal: optimal.first(limit).map(&:crop), tolerable: tolerable.first(limit).map(&:crop) }
  end

  private

  # Every approved crop with a record and a cycle length, the most planted first.
  def candidates
    @candidates ||= Crop.approved
      .joins('LEFT JOIN crops parents ON parents.id = crops.parent_id')
      .joins('INNER JOIN ecocrop_data ON ecocrop_data.id = COALESCE(crops.ecocrop_data_id, parents.ecocrop_data_id)')
      .where('ecocrop_data.gmin IS NOT NULL AND ecocrop_data.topmn IS NOT NULL AND ecocrop_data.topmx IS NOT NULL')
      .select('crops.*, ecocrop_data.topmn AS best_min, ecocrop_data.topmx AS best_max, ecocrop_data.tmin AS kill_min, ' \
              'ecocrop_data.tmax AS kill_max, ecocrop_data.gmin AS quick_days, ecocrop_data.gmax AS slow_days')
      .order(Arel.sql('crops.plantings_count DESC, lower(crops.name) ASC'))
      .map { |crop| Candidate.new(crop, *crop.attributes.values_at(*Candidate.members.drop(1).map(&:to_s))) }
  end

  # Whether a sowing in any of the months gets through the cycle: at its best, or only surviving.
  def fits?(candidate, months, best:)
    days = best ? candidate.quick_days : (candidate.slow_days || candidate.quick_days)
    needed = [(days / DAYS_IN_MONTH).ceil, 12].min
    months.any? do |start|
      cycle = (0...needed).map { |offset| ((start - 1 + offset) % 12) + 1 }
      cycle.all? { |month| survives?(candidate, month) && (!best || best?(candidate, month)) }
    end
  end

  # Whether the days' usual high in the month is in the crop's best range. A plant does its growing in the day, so the high is
  # compared, not the average of the whole day and night, which runs well below it.
  def best?(candidate, month)
    high = @days[month]
    high && high >= candidate.best_min && high <= candidate.best_max
  end

  # Whether the month's nights and days stay within what the crop survives. A month we hold no weather for does not.
  def survives?(candidate, month)
    night = @nights[month]
    day = @days[month]
    return false unless night && day

    (candidate.kill_min.nil? || night >= candidate.kill_min) && (candidate.kill_max.nil? || day <= candidate.kill_max)
  end
end

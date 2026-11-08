# frozen_string_literal: true

# The frost danger of a place for the year around a day: the usual and the possible dates, a verdict for today, and where
# they fall on a timeline of whole months. It holds the working out and no text, so a page only has to draw it.
# PlantingFrost adds a planting to it.
#
# The usual dates are the medians of past years and the possible ones are the earliest and latest it has come: see
# FrostStat. Approximate, regional and experimental.
class FrostSeason
  # A stretch of the timeline. kind is :usual or :possible for frost danger, and :so_far, :still_to_come or :finished
  # for a planting. open is true when the timeline cuts the band off before its real end.
  Band = Struct.new(:kind, :from, :to, :open)

  THRESHOLD_C = FrostCalculator::FROST_DANGER_C
  SOON_DAYS = 60

  attr_reader :today

  # place: a Garden or a Planting, which have a frost_danger. Nil when there are no dates for it to work from.
  def self.for(place, today: Time.zone.today)
    stat = place.frost_danger
    new(stat:, today:) if stat && !stat.unknown?
  end

  def initialize(stat:, today:)
    @stat = stat
    @today = today
  end

  # What to tell the member today: where today falls in the frost danger season of the year.
  def verdict
    return :rare unless @stat.dated?

    if @today < usual.first then :before_season
    elsif @today <= usual.last then :in_season
    elsif @today <= possible.last then :late_possible
    else :passed
    end
  end

  # The usual frost danger of the year, from the median first frost to the median last.
  def usual
    @usual ||= season_dates(year, :first_frost_median, :last_frost_median)
  end

  # The earliest and the latest it has come in that year's place.
  def possible
    @possible ||= season_dates(year, :first_frost_p10, :last_frost_p90)
  end

  def next_season_start
    @stat.date_for(:first_frost_median, year + 1)
  end

  def next_season_earliest
    @stat.date_for(:first_frost_p10, year + 1)
  end

  def days_until_usual_start
    (usual.first - @today).to_i
  end

  # Whether the usual first frost is near enough to say it is coming, rather than a long way off.
  def starts_soon?
    days_until_usual_start <= SOON_DAYS
  end

  def days_until_usual_end
    (usual.last - @today).to_i
  end

  def days_until_latest
    (possible.last - @today).to_i
  end

  def days_since_latest
    (@today - possible.last).to_i
  end

  def days_to_next_season
    (next_season_start - lived_until).to_i
  end

  # The typical frost-free days of the place, from the frost dates, or nil when they have none.
  def frost_free_days
    @stat.frost_free_days_median&.round
  end

  # The dates the timeline covers: whole months, from the earliest possible frost to a month past the start of the next season.
  def axis
    @axis ||= axis_first.beginning_of_month..axis_last.end_of_month
  end

  # Whether today is a day on the timeline worth marking.
  def show_today?
    axis.cover?(today)
  end

  # The frost danger on the timeline, for the year and the next, cut to the axis.
  def danger_bands
    [year, year + 1].flat_map { |y| bands_for(y) }.filter_map { |band| clip(band) }
  end

  # What else is on the timeline: nothing, for a place alone.
  def planting_bands
    []
  end

  # How far along the axis a date is, from 0 to 1.
  def position(date)
    ((date - axis.first).to_f / axis_days).clamp(0.0, 1.0)
  end

  # How much of the axis a band covers, from 0 to 1.
  def width(band)
    position(band.to + 1) - position(band.from)
  end

  private

  # The day the year is the frost year of.
  def season_day
    @today
  end

  def year
    @year ||= @stat.frost_year_of(season_day)
  end

  # The last day that matters on the timeline, for the next season to be measured from.
  def lived_until
    @today
  end

  def axis_first
    possible.first
  end

  def axis_last
    next_season_start.next_month
  end

  def season_dates(season_year, first, last)
    @stat.date_for(first, season_year)..@stat.date_for(last, season_year)
  end

  def bands_for(season_year)
    earliest, first, last, latest = %i(first_frost_p10 first_frost_median last_frost_median last_frost_p90).map do |field|
      @stat.date_for(field, season_year)
    end
    [Band.new(:possible, earliest, first - 1), Band.new(:usual, first, last), Band.new(:possible, last + 1, latest)]
  end

  def clip(band)
    from = [band.from, axis.first].max
    to = [band.to, axis.last].min
    Band.new(band.kind, from, to, band.to > axis.last) if from <= to
  end

  def axis_days
    axis.last - axis.first + 1
  end
end

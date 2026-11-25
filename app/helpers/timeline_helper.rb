# frozen_string_literal: true

# The timeline on a planting's page: working out its entries, and the words, icons and colours of the ones the weather makes.
module TimelineHelper
  include FrostSectionHelper

  # One line of the timeline: when, what kind of entry (:observation, :harvest, :job, :planted, :transplanted, :frost_passed or
  # one of the weather kinds in WEATHER_ENTRIES) and what it is about. That is the Observation for an observation, the Harvest
  # for a harvest, the Job for a job done, the PlantingHistory for a move out of the nursery, the day for frost danger passing,
  # the run of conditions for the weather kinds (see #condition_runs), and nothing for the planting itself.
  TimelineEntry = Struct.new(:at, :type, :record)

  # Of entries on one day, the planting comes first in time, then the weather, the harvests, the jobs, then what was noticed.
  TIMELINE_ORDER = %i(planted transplanted frost killing_cold killing_heat damaging_wind heavy_rain extreme_heat first_snow
                      frost_passed harvest job observation).freeze

  # The entries the weather makes: their icon, and the classes that colour the row.
  WEATHER_ENTRIES = {
    frost:         { icon: 'snowflake', classes: 'observation-frost' },
    killing_cold:  { icon: 'temperature-low', classes: 'observation-problem' },
    killing_heat:  { icon: 'temperature-high', classes: 'observation-problem observation-hot' },
    damaging_wind: { icon: 'wind', classes: 'observation-problem' },
    heavy_rain:    { icon: 'cloud-showers-heavy', classes: 'observation-problem' },
    extreme_heat:  { icon: 'sun', classes: 'observation-problem observation-hot' },
    first_snow:    { icon: 'snowman', classes: 'observation-frost' }
  }.freeze

  COMPASS_POINTS = %w(north north_east east south_east south south_west west north_west).freeze

  # What the timeline lists, newest first: the observations, the planting itself, which has no observation, on the day it
  # went in, its harvests, the jobs done on it, the day frost danger passed, and its conditions (nights of frost and days too
  # cold or hot for the crop, each run of days in a row as one entry), which nobody has to note.
  def observation_timeline(planting, observations, conditions: [], harvests: [], jobs: [], frost_passed_on: nil, histories: []) # rubocop:disable Metrics/ParameterLists
    entries = observations.map { |observation| TimelineEntry.new(observation.observed_at, :observation, observation) }
    entries << TimelineEntry.new(planting.planted_at.in_time_zone, :planted) if planting.planted_at.present?
    entries += harvests.map { |harvest| TimelineEntry.new((harvest.harvested_at || harvest.created_at).in_time_zone, :harvest, harvest) }
    entries += jobs.map { |job| TimelineEntry.new((job.finished_at || job.updated_at).in_time_zone, :job, job) }
    moves = histories.select { |history| history.garden.nursery? }
    entries += moves.map { |history| TimelineEntry.new(history.ended_on.in_time_zone, :transplanted, history) }
    entries << TimelineEntry.new(frost_passed_on.in_time_zone, :frost_passed, frost_passed_on) if frost_passed_on
    entries += condition_runs(conditions).map { |run| TimelineEntry.new(run.first.occurred_on.in_time_zone, run.first.kind.to_sym, run) }
    entries.sort_by { |entry| [entry.at, TIMELINE_ORDER.index(entry.type)] }.reverse
  end

  # The partial in plantings/observations that draws an entry. The weather kinds share one.
  def timeline_partial(type)
    WEATHER_ENTRIES.key?(type) ? 'weather' : type.to_s
  end

  # An entry's date, and how many days into the planting that was if we know when it was planted.
  def timeline_when(at, planting)
    date = at.to_date
    day = timeline_day(date, planting)
    tag.div(class: 'observation-when') do
      safe_join([tag.time(l(date), datetime: date.iso8601),
                 (tag.span(t('plantings.observations.day', count: day), class: 'observation-day') if day)])
    end
  end

  # How many days into the planting a date is, if we know when it was planted.
  def timeline_day(date, planting)
    return if planting.planted_at.blank?

    days = (date - planting.planted_at).to_i
    days if days >= 0
  end

  # What a run of weather days draws as: { icon:, classes:, title:, note: }, with the figures of the strongest of them.
  def weather_entry(type, run, planting)
    title = t("plantings.observations.weather.#{type}.title", count: run.size)
    WEATHER_ENTRIES.fetch(type).merge(title:, note: weather_entry_note(type, run, planting))
  end

  # What the "Planted" entry adds: where it was sown, if somewhere safe from frost like the nursery, and what it was started
  # from: a seed packet we hold, or another way (a seedling, a cutting) when it says so. Nil when we know none of it.
  def planted_note(planting)
    sentences = [planted_place(planting), planted_origin(planting)].compact
    safe_join(sentences, ' ') if sentences.any?
  end

  private

  # The conditions grouped into runs of one kind on days in a row: [[night, night], [night]], each run oldest first.
  def condition_runs(conditions)
    conditions.group_by(&:kind).values.flat_map do |kind|
      kind.sort_by(&:occurred_on).chunk_while { |one, other| other.occurred_on == one.occurred_on + 1 }.to_a
    end
  end

  def weather_entry_note(type, run, planting)
    figures = run.filter_map(&:value)
    scope = "plantings.observations.weather.#{type}.note"
    limit = frost_degrees(run.first.threshold) if type.in?(%i(killing_cold killing_heat))
    case type
    when :frost then t(scope, degrees: frost_degrees(figures.min))
    when :killing_cold then t(scope, degrees: frost_degrees(figures.min), limit:, crop: planting.crop_name)
    when :killing_heat then t(scope, degrees: frost_degrees(figures.max), limit:, crop: planting.crop_name)
    when :damaging_wind then damaging_wind_note(run)
    when :heavy_rain then t(scope, amount: number_with_precision(figures.max, precision: 0))
    when :extreme_heat then t(scope, degrees: frost_degrees(figures.max))
    when :first_snow then t(scope, amount: frost_degrees(figures.max))
    end
  end

  # "Gusts up to 112 km/h from the south-west, 8 to 14 °C that day.", for the strongest day of a run.
  def damaging_wind_note(run)
    day = run.max_by { |condition| condition.value.to_f }
    direction = wind_direction_name(day.direction_degrees)
    gusts = t('observations.wind.gusts', speed: number_with_precision(day.value, precision: 0))
    gusts = "#{gusts} #{t('observations.wind.from', direction:)}" if direction
    "#{[gusts, wind_temperatures(day)].compact.join(', ')}."
  end

  # "8 to 14 °C that day", or nil when we don't have both.
  def wind_temperatures(day)
    return unless day.temp_min_c && day.temp_max_c

    t('observations.wind.temperature', low: frost_degrees(day.temp_min_c), high: frost_degrees(day.temp_max_c))
  end

  # Where the wind blew from, in words: "south-west". Nil when we don't know.
  def wind_direction_name(degrees)
    return unless degrees

    t("observations.compass.#{COMPASS_POINTS[((degrees % 360) / 45.0).round % 8]}")
  end

  def planted_place(planting)
    garden = planting.in_nursery? ? planting.garden : planting.frost_safe_stay&.garden
    return unless garden

    garden.nursery? ? t('plantings.observations.planted.in_nursery') : t('plantings.observations.planted.in', garden: garden.name)
  end

  def planted_origin(planting)
    if planting.parent_seed
      packet = link_to(t('plantings.observations.planted.packet_link'), planting.parent_seed)
      t('plantings.observations.planted.from_packet_html', packet:)
    elsif planting.planted_from.present?
      kind = t("plantings.origin.kinds.#{planted_from_key(planting.planted_from)}").downcase
      t('plantings.observations.planted.started_as', kind: [kind, planted_seedling_details(planting)].compact_blank.join(' · '))
    end
  end

  # Where a seedling came from, as the member put it: "Shop or garden centre · Kiwi Seedlings".
  def planted_seedling_details(planting)
    seedling = planting.seedling
    return unless seedling

    [(t("plantings.origin.seedling_sources.#{seedling.source}") if seedling.source), seedling.supplier].compact_blank.join(' · ').presence
  end
end

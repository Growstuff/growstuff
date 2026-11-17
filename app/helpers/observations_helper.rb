# frozen_string_literal: true

module ObservationsHelper
  ICONS = {
    'germination' => 'seedling', 'flowering' => 'spa', 'fruiting' => 'apple-whole',
    'wilting' => 'arrow-trend-down', 'disease_observed' => 'bug'
  }.freeze

  # One line of the timeline: when, what kind of entry (:observation, :harvest, :job, :planted, :frost, :killing_cold,
  # :killing_heat, :damaging_wind or :frost_passed) and what it is about. That is the Observation for an observation, the Harvest for a harvest,
  # the Job for a job done, the day for frost danger passing, the run of PlantingConditions for the weather kinds (see
  # #condition_runs), and nothing for the planting itself.
  TimelineEntry = Struct.new(:at, :type, :record)

  # Of entries on one day, the planting comes first in time, then the weather, the harvests, the jobs, then what was noticed.
  TIMELINE_ORDER = %i(planted frost killing_cold killing_heat damaging_wind frost_passed harvest job observation).freeze

  # The kinds of observation to choose from, with their wording. Observations with no kind are "other".
  def observation_kind_options
    @observation_kind_options ||= (Observation::KINDS + ['other']).map do |kind|
      { value: kind, label: observation_kind_label(kind), icon: observation_icon_name(kind) }
    end
  end

  # The icon on an observation's place on the timeline and in the dialog; "other" has a question mark.
  def observation_icon(kind)
    icon 'fas', observation_icon_name(kind)
  end

  # What the edit dialog starts from.
  def observation_edit_data(observation)
    { id: observation.id, kind: observation.kind, observed_on: observation.observed_at.to_date.iso8601,
      description: observation.description }
  end

  def observation_icon_name(kind)
    ICONS.fetch(kind, 'circle-question')
  end

  def observation_kind_label(kind)
    t("observations.kinds.#{kind || 'other'}")
  end

  # What the timeline lists, newest first: the observations, the planting itself, which has no observation, on the day it
  # went in, its harvests, the jobs done on it, the day frost danger passed, and its conditions (nights of frost and days too
  # cold or hot for the crop, each run of days in a row as one entry), which nobody has to note.
  def observation_timeline(planting, observations, conditions: [], harvests: [], jobs: [], frost_passed_on: nil) # rubocop:disable Metrics/ParameterLists
    entries = observations.map { |observation| TimelineEntry.new(observation.observed_at, :observation, observation) }
    entries << TimelineEntry.new(planting.planted_at.in_time_zone, :planted) if planting.planted_at.present?
    entries += harvests.map { |harvest| TimelineEntry.new((harvest.harvested_at || harvest.created_at).in_time_zone, :harvest, harvest) }
    entries += jobs.map { |job| TimelineEntry.new((job.finished_at || job.updated_at).in_time_zone, :job, job) }
    entries << TimelineEntry.new(frost_passed_on.in_time_zone, :frost_passed, frost_passed_on) if frost_passed_on
    entries += condition_runs(conditions).map { |run| TimelineEntry.new(run.first.occurred_on.in_time_zone, run.first.kind.to_sym, run) }
    entries.sort_by { |entry| [entry.at, TIMELINE_ORDER.index(entry.type)] }.reverse
  end

  # The conditions grouped into runs of one kind on days in a row: [[night, night], [night]], each run oldest first.
  def condition_runs(conditions)
    conditions.group_by(&:kind).values.flat_map do |kind|
      kind.sort_by(&:occurred_on).chunk_while { |one, other| other.occurred_on == one.occurred_on + 1 }.to_a
    end
  end

  COMPASS_POINTS = %w(north north_east east south_east south south_west west north_west).freeze

  # Where the wind blew from, in words: "south-west". Nil when we don't know.
  def wind_direction_name(degrees)
    return unless degrees

    t("observations.compass.#{COMPASS_POINTS[((degrees % 360) / 45.0).round % 8]}")
  end

  # What a run of damaging wind days says of the strongest of them: "Gusts up to 112 km/h from the south-west, 8 to 14 °C that
  # day."
  def damaging_wind_note(run)
    day = run.max_by { |condition| condition.value.to_f }
    direction = wind_direction_name(day.direction_degrees)
    gusts = t('observations.wind.gusts', speed: number_with_precision(day.value, precision: 0))
    gusts = "#{gusts} #{t('observations.wind.from', direction:)}" if direction
    temperature = t('observations.wind.temperature', low: frost_degrees(day.temp_min_c), high: frost_degrees(day.temp_max_c)) if day.temp_min_c && day.temp_max_c
    "#{[gusts, temperature].compact.join(', ')}."
  end

  # How many days into the planting it was noticed, if we know when it was planted.
  def observation_day(observation, planting)
    timeline_day(observation.observed_at.to_date, planting)
  end

  # How many days into the planting a date is, if we know when it was planted.
  def timeline_day(date, planting)
    return if planting.planted_at.blank?

    days = (date - planting.planted_at).to_i
    days if days >= 0
  end
end

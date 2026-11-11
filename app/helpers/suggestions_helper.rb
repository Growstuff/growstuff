# frozen_string_literal: true

# The props of the SeasonSuggestions island on the suggestions page: the four seasons with their figures as text, the one
# open with its crops already in, and the words and addresses it needs, so the island holds no translation of its own.
module SuggestionsHelper
  def season_island_props(climate:, selected:, payload:, enabled:)
    {
      seasons: climate.seasons.map { |season| season_summary(season) },
      open:    selected&.name,
      enabled:,
      initial: payload ? { payload[:season] => payload } : {},
      urls:    { jobs: suggested_jobs_path, dismiss: crop_dismissals_path, planned: jobs_path },
      labels:  season_island_labels
    }
  end

  # The address of the photo for a suggested crop's card, or the placeholder.
  def suggested_crop_image(crop)
    image_path(crop.default_photo&.thumbnail_url || placeholder_image)
  end

  private

  def season_summary(season)
    {
      name: season.name, title: t("seasons.#{season.name}"), current: season.current, hasData: season.mean.present?,
      months: season_months(season), mean: season.mean && degrees(season.mean), url: suggestions_season_path(season.name),
      figures: season_figures(season)
    }
  end

  def season_months(season)
    first, last = season.months.values_at(0, -1).map { |month| l(Date.new(2000, month, 1), format: '%b') }
    t('suggestions.climate.months', first:, last:)
  end

  # The nights, the days and the rain of the season that we hold figures for, as { label:, value: }.
  def season_figures(season)
    [
      [:nights, season.night && degrees(season.night)],
      [:days, season.day && degrees(season.day)],
      [:rain, season.rain && t('suggestions.climate.millimetres', value: number_with_precision(season.rain, precision: 0, delimiter: ','))]
    ].filter_map { |key, value| { label: t("suggestions.climate.#{key}"), value: } if value }
  end

  def degrees(value)
    t('suggestions.climate.degrees', value: number_with_precision(value, precision: 0))
  end

  def season_island_labels
    {
      average: t('suggestions.climate.average'), now: t('suggestions.climate.now'), loading: t('suggestions.climate.loading'),
      loadFailed: t('suggestions.climate.load_failed'), retry: t('suggestions.climate.retry'), noData: t('suggestions.climate.no_data'),
      noCrops: t('suggestions.climate.no_crops'), off: t('home.dashboard.suggestions_off'), addToJobs: t('suggestions.climate.add_to_jobs'),
      planned: t('suggestions.climate.planned'), growing: t('suggestions.climate.growing'), notForMe: t('home.dashboard.not_for_me')
    }
  end
end

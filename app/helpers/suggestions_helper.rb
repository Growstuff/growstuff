# frozen_string_literal: true

# The props of the SeasonSuggestions island on the suggestions page: the four seasons with their figures as text, the one
# open with its crops already in, and the words and addresses it needs, so the island holds no translation of its own.
module SuggestionsHelper
  # A visitor who isn't signed in has no member: nearest is the weather held near them, whose position goes in each season's
  # address, and the island leaves out the buttons that need an account.
  def season_island_props(climate:, selected:, payload:, enabled:, nearest: nil)
    {
      seasons: climate.seasons.map { |season| season_island_row(season, nearest) },
      guest:   nearest.present?,
      open:    selected&.name,
      enabled:,
      initial: payload ? { payload[:season] => payload } : {},
      urls:    { jobs: suggested_jobs_path, dismiss: crop_dismissals_path, planned: jobs_path },
      labels:  season_island_labels.merge(nearest ? retrieving_label(nearest) : {})
    }
  end

  # The address of the photo for a suggested crop's card, or the placeholder.
  def suggested_crop_image(crop)
    image_path(crop.default_photo&.thumbnail_url || placeholder_image)
  end

  private

  # While a visitor's crops load the island says whose weather it is fetching them for.
  def retrieving_label(nearest)
    place = nearest.place_name || t('suggestions.introduction.unnamed_place')
    { loading: t('suggestions.introduction.retrieving', place:) }
  end

  def season_island_row(season, nearest)
    {
      name: season.name, title: t("seasons.#{season.name}"), icon: SeasonsHelper::SEASON_ICONS.fetch(season.name.to_sym),
      current: season.current, hasData: season.mean.present?,
      months: season_island_months(season), mean: season.mean && island_degrees(season.mean),
      url: suggestions_season_path(season.name, **nearest_position(nearest)),
      figures: season_island_figures(season)
    }
  end

  def season_island_months(season)
    first, last = season.months.values_at(0, -1).map { |month| l(Date.new(2000, month, 1), format: '%b') }
    t('suggestions.climate.months', first:, last:)
  end

  def nearest_position(nearest)
    nearest ? { lat: params[:lat], lng: params[:lng] } : {}
  end

  # The nights, the days and the rain of the season that we hold figures for, as { label:, value: }.
  def season_island_figures(season)
    [
      [:usual_night, season.night_usual && island_degrees(season.night_usual)],
      [:nights, season.night && island_degrees(season.night)],
      [:usual_day, season.day_usual && island_degrees(season.day_usual)],
      [:days, season.day && island_degrees(season.day)],
      [:rain, season.rain && t('suggestions.climate.millimetres', value: number_with_precision(season.rain, precision: 0, delimiter: ','))]
    ].filter_map { |key, value| { label: t("suggestions.climate.#{key}"), value: } if value }
  end

  def island_degrees(value)
    t('suggestions.climate.degrees', value: number_with_precision(value, precision: 0))
  end

  def season_island_labels
    {
      average: t('suggestions.climate.average'), now: t('suggestions.climate.now'), loading: t('suggestions.climate.loading'),
      loadFailed: t('suggestions.climate.load_failed'), retry: t('suggestions.climate.retry'), noData: t('suggestions.climate.no_data'),
      noCrops: t('suggestions.climate.no_crops'), off: t('home.dashboard.suggestions_off'),
      addToJobs: t('suggestions.climate.add_to_jobs'), addFailed: t('suggestions.climate.add_failed'),
      planned: t('suggestions.climate.planned'), growing: t('suggestions.climate.growing'), notForMe: t('home.dashboard.not_for_me')
    }
  end
end

# frozen_string_literal: true

# The climate at the member's home through the four seasons, and for each season the crops to grow in it: what gardeners at
# their latitude plant then, and the crops whose temperatures suit it, as an island that opens a season and fetches its crops
# (#season) when it is opened. The season in progress, or the one ?season= names, comes with the page. Also the switch for
# turning the suggestions off or on.
class SuggestionsController < ApplicationController
  # How many crops to list for a season, of each kind.
  SEASON_CROPS = 12

  skip_authorize_resource
  before_action :authenticate_member!
  before_action :load_climate, only: %i(index season)

  def index
    @season = @climate&.selected(params[:season])
    current_member.request_climate unless @climate
    @season_payload = season_payload(@season) if crops_wanted?(@season)
  end

  # GET /suggestions/seasons/winter.json
  def season
    season = @climate&.seasons&.find { |candidate| candidate.name.to_s == params[:season] }
    return head :not_found unless crops_wanted?(season)

    render json: season_payload(season)
  end

  def update
    current_member.update_columns(suggest_crops: params[:suggest] == 'true') # rubocop:disable Rails/SkipsModelValidations
    redirect_back_or_to suggestions_path, notice: t(current_member.suggest_crops ? '.enabled' : '.disabled')
  end

  private

  def load_climate
    @dashboard = MemberDashboard.new(current_member)
    @climate = SeasonalClimate.for(current_member)
  end

  # Whether there are crops to suggest for the season: it has weather, and suggestions are on.
  def crops_wanted?(season)
    season&.mean && @dashboard.suggestions_enabled?
  end

  # What the island shows for the season: its groups of crops, each with a heading, as cards.
  def season_payload(season)
    dismissed = current_member.crop_dismissals.pluck(:crop_id)
    fitting = SeasonalCrops.new(@climate).sown_in(season.months, limit: SEASON_CROPS, except: dismissed)
    planting = @dashboard.sowing_in(season.months, SEASON_CROPS)
    crops = (fitting.values.flatten + planting).uniq
    ActiveRecord::Associations::Preloader.new(records: crops, associations: [:photos, :ecocrop_record, { parent: :ecocrop_record }]).call
    @followed = @dashboard.followed_growing(crops.map(&:id))
    @grown_before = @dashboard.grown_in_past(crops.map(&:id))
    name = t("seasons.#{season.name}").downcase
    place = current_member.location_place || current_member.location.presence || t('suggestions.climate.your_location')
    { season: season.name, groups: [
      group(season, planting, t('suggestions.climate.planting', season: name, place:)),
      group(season, fitting[:optimal], t('suggestions.climate.suits', season: name, place:)),
      group(season, fitting[:tolerable], t('suggestions.climate.still_grows', season: name, place:))
    ].zip(%w(planting optimal tolerable)).map { |group, key| group.merge(key:) } }
  end

  def group(season, crops, heading)
    { heading:, crops: crops.map { |crop| card(crop, season) } }
  end

  def card(crop, season)
    record = crop.ecocrop_record || crop.parent&.ecocrop_record
    { id: crop.id, name: crop.name, path: crop_path(crop), image: helpers.suggested_crop_image(crop), note: best_range(record),
      timing: timing(record, season), planned: planned_jobs.planned?(crop, season.name), growing: @dashboard.growing?(crop),
      grown_before: grown_before_note(crop), followed: followed_note(crop) }
  end

  # The last years the member planted the crop in before this one, as "You grew this in 2023 and 2024", or nil.
  def grown_before_note(crop)
    years = @grown_before.fetch(crop.id, [])
    t('suggestions.climate.grown_before', years: years.last(3).to_sentence) if years.any?
  end

  # Who the member follows is growing the crop, as "People you follow growing this: ann and bo", or nil.
  def followed_note(crop)
    names = @followed.fetch(crop.id, [])
    t('suggestions.climate.followed_grow', names: names.first(3).to_sentence) if names.any?
  end

  def best_range(record)
    t('suggestions.climate.best_range', low: record.topmn, high: record.topmx) if record&.topmn && record.topmx
  end

  # How long the crop takes, and when it is ready if sown at the start of the season: "90 to 120 days, ready in early autumn".
  def timing(record, season)
    return unless record&.gmin

    low = record.gmin
    high = record.gmax || low
    days = high == low ? t('suggestions.climate.duration', count: low) : t('suggestions.climate.duration_range', low:, high:)
    ready = @climate.ready(season, (low + high) / 2.0)
    t('suggestions.climate.timing', days:, ready: t('suggestions.climate.ready_in', part:   t("suggestions.climate.part_#{ready[:part]}"),
                                                                                    season: t("seasons.#{ready[:season]}").downcase))
  end

  def planned_jobs
    @planned_jobs ||= SuggestedPlantJob.new(current_member, @climate)
  end
end

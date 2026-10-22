# frozen_string_literal: true

# What to offer when a member types @ and a crop name in a job: each matching
# crop's plantings and seeds that are theirs, then the crop itself.
class JobSuggestionsController < ApplicationController
  MAX_CROPS = 4
  MAX_SUGGESTIONS = 10

  before_action :authenticate_member!

  def index
    query = params[:q].to_s.strip
    return render(json: []) if query.blank?

    crops = Crop.popular.where('crops.name ILIKE ?', "#{Crop.sanitize_sql_like(query)}%").limit(MAX_CROPS)
    render json: crops.flat_map { |crop| suggestions_for(crop) }.first(MAX_SUGGESTIONS)
  end

  private

  def suggestions_for(crop)
    plantings = current_member.plantings.active.where(crop:).includes(:garden)
    seeds = current_member.seeds.current.where(crop:)

    plantings.map { |planting| planting_suggestion(planting) } +
      seeds.map { |seed| seed_suggestion(seed) } +
      [{ kind: 'crop', jobbable_type: 'Crop', jobbable_id: crop.id, crop_name: crop.name, label: crop.name,
         detail: t('jobs.suggestions.the_crop'), icon_url: icon_url(crop) }]
  end

  def planting_suggestion(planting)
    detail = t('jobs.suggestions.planted', date: l(planting.planted_at, format: '%-d %b')) if planting.planted_at
    { kind: 'planting', jobbable_type: 'Planting', jobbable_id: planting.id, crop_name: planting.crop.name,
      label: [planting.crop.name, planting.garden&.name].compact.join(', '), detail:, icon_url: icon_url(planting.crop) }
  end

  def seed_suggestion(seed)
    detail = t('jobs.suggestions.saved', year: seed.saved_at.year) if seed.saved_at
    { kind: 'seed', jobbable_type: 'Seed', jobbable_id: seed.id, crop_name: seed.crop.name,
      label: t('jobs.suggestions.seeds', crop: seed.crop.name), detail:, icon_url: icon_url(seed.crop) }
  end

  # The crop's icon, or the sprout when it has none.
  def icon_url(crop)
    crop_path(crop, format: 'svg')
  end
end

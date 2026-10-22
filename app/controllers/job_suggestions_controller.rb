# frozen_string_literal: true

# What to offer when a member types @ and a crop name in a job: each matching
# crop's plantings and seeds that are theirs, then the crop itself. In a garden's
# to-do list, only the plantings in that garden.
class JobSuggestionsController < ApplicationController
  MAX_CROPS = 4
  MAX_SUGGESTIONS = 10

  before_action :authenticate_member!

  def index
    query = params[:q].to_s.strip
    return render(json: []) if query.blank?

    crops = Crop.popular.where('crops.name ILIKE ?', "#{Crop.sanitize_sql_like(query)}%")
    crops = crops.where(id: plantings.select(:crop_id)) if garden
    render json: crops.limit(MAX_CROPS).flat_map { |crop| suggestions_for(crop) }.first(MAX_SUGGESTIONS)
  end

  private

  # The garden whose to-do list this is for, if it is for one.
  def garden
    Garden.find_by(id: params[:garden_id]) if params[:garden_id].present?
  end

  # The member's plantings that are still growing: in the garden, if there is one.
  def plantings
    plantings = current_member.plantings.active
    garden ? plantings.where(garden:) : plantings
  end

  def suggestions_for(crop)
    suggestions = plantings.where(crop:).includes(:garden).map { |planting| planting_suggestion(planting) }
    return suggestions if garden

    suggestions + current_member.seeds.current.where(crop:).map { |seed| seed_suggestion(seed) } +
      [{ jobbable_type: 'Crop', jobbable_id: crop.id, crop_name: crop.name, label: crop.name,
         detail: t('jobs.suggestions.the_crop'), icon_url: icon_url(crop) }]
  end

  def planting_suggestion(planting)
    detail = t('jobs.suggestions.planted', date: l(planting.planted_at, format: '%-d %b')) if planting.planted_at
    { jobbable_type: 'Planting', jobbable_id: planting.id, crop_name: planting.crop.name,
      label: [planting.crop.name, (planting.garden&.name unless garden)].compact.join(', '), detail:, icon_url: icon_url(planting.crop) }
  end

  def seed_suggestion(seed)
    detail = t('jobs.suggestions.saved', year: seed.saved_at.year) if seed.saved_at
    { jobbable_type: 'Seed', jobbable_id: seed.id, crop_name: seed.crop.name,
      label: t('jobs.suggestions.seeds', crop: seed.crop.name), detail:, icon_url: icon_url(seed.crop) }
  end

  # The crop's icon, or the sprout when it has none.
  def icon_url(crop)
    crop_path(crop, format: 'svg')
  end
end

# frozen_string_literal: true

# What to offer when a member types @ in a job: matching beds (gardens),
# matching crops with their plantings and seeds, or plantings matching by variety
# or bed name. In a garden's to-do list, only the plantings in that garden.
class JobSuggestionsController < ApplicationController
  MAX_CROPS = 4
  MAX_SUGGESTIONS = 10

  before_action :authenticate_member!

  def index
    query = params[:q].to_s.strip
    return render(json: []) if query.blank?

    render json: all_suggestions(query).first(MAX_SUGGESTIONS)
  end

  private

  # The garden whose to-do list this is for, if it is for one.
  def garden
    Garden.find_by(id: params[:garden_id]) if params[:garden_id].present?
  end

  # The member's plantings that are still growing: in the garden, if there is one,
  # or in any garden they own or collaborate on.
  def plantings
    return garden.plantings.active if garden

    Planting.active.where(garden_id: current_member.accessible_gardens)
  end

  def all_suggestions(query)
    if garden
      garden_plantings_for(query)
    else
      suggestions = []
      suggestions.concat(matching_gardens(query).map { |g| garden_suggestion(g) })
      suggestions.concat(crop_and_seed_suggestions(query))
      suggestions.concat(matching_plantings(query).map { |p| planting_suggestion(p) })
      suggestions.uniq { |s| [s[:jobbable_type], s[:jobbable_id]] }
    end
  end

  def garden_plantings_for(query)
    crop_plantings = matching_crops(query).flat_map { |crop| suggestions_for(crop) }
    direct_plantings = matching_plantings(query).map { |p| planting_suggestion(p) }
    (crop_plantings + direct_plantings).uniq { |s| s[:jobbable_id] }
  end

  def matching_crops(query)
    crops = Crop.popular.where('crops.name ILIKE ?', "#{Crop.sanitize_sql_like(query)}%")
    crops = crops.where(id: plantings.select(:crop_id)) if garden
    crops.limit(MAX_CROPS)
  end

  def crop_and_seed_suggestions(query)
    matching_crops(query).flat_map { |crop| suggestions_for(crop) }
  end

  def matching_gardens(query)
    sanitized = Garden.sanitize_sql_like(query)
    current_member.gardens.active
      .where('gardens.name ILIKE ?', "%#{sanitized}%")
      .order(Arel.sql(ActiveRecord::Base.sanitize_sql_array(['CASE WHEN gardens.name ILIKE ? THEN 0 ELSE 1 END', "#{sanitized}%"])), :name)
  end

  def matching_plantings(query)
    sanitized = Crop.sanitize_sql_like(query)
    scope = plantings.left_joins(:crop, :alternate_name)
    scope = if garden
              scope.where('crops.name ILIKE :like OR alternate_names.name ILIKE :like', like: "%#{sanitized}%")
            else
              scope.left_joins(:garden).where(
                'crops.name ILIKE :like OR alternate_names.name ILIKE :like OR gardens.name ILIKE :like',
                like: "%#{sanitized}%"
              )
            end
    scope.includes(:crop, :alternate_name, :garden)
      .order(Arel.sql(ActiveRecord::Base.sanitize_sql_array(['CASE WHEN crops.name ILIKE ? THEN 0 ELSE 1 END', "#{sanitized}%"])), :planted_at)
  end

  def suggestions_for(crop)
    suggestions = plantings.where(crop:).includes(:garden).map { |planting| planting_suggestion(planting) }
    return suggestions if garden

    suggestions + current_member.seeds.current.where(crop:).map { |seed| seed_suggestion(seed) } +
      [{ jobbable_type: 'Crop', jobbable_id: crop.id, crop_name: crop.name, label: crop.name,
         detail: t('jobs.suggestions.the_crop'), icon_url: icon_url(crop) }]
  end

  def garden_suggestion(garden)
    {
      garden_id: garden.id,
      jobbable_type: 'Garden',
      jobbable_id: garden.id,
      crop_name: garden.name,
      label: garden.name,
      detail: t('jobs.pad.garden'),
      icon_url: ActionController::Base.helpers.image_path('icons/gardens.svg')
    }
  end

  def planting_suggestion(planting)
    detail = t('jobs.suggestions.planted', date: l(planting.planted_at, format: '%-d %b')) if planting.planted_at
    crop_name = planting.display_name
    label = [crop_name, (planting.garden&.name unless garden)].compact.join(', ')
    { jobbable_type: 'Planting', jobbable_id: planting.id, crop_name:,
      label:, detail:, icon_url: icon_url(planting.crop) }
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

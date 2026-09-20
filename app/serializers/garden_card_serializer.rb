# frozen_string_literal: true

# The data one garden card needs, as plain hashes for the React GardenCards
# island. It mirrors what gardens/_card, gardens/_actions and the planting
# partials (_progress_list, _badges, _quick_actions) render today, so the
# server still decides labels, links and permissions and React just draws them.
#
# Use GardenCardSerializer.collection for a page of gardens: it loads the
# active plantings for all of them in one go, rather than per garden.
class GardenCardSerializer
  include PhotosHelper

  def self.collection(gardens, ability:, show_owner: true)
    gardens = gardens.to_a
    plantings = Planting.active
      .where(garden_id: gardens.map(&:id))
      .includes(:harvests, crop: { parent: :parent })
      .order(:planted_at)
      .group_by(&:garden_id)

    gardens.map do |garden|
      new(garden, plantings: plantings.fetch(garden.id, []), ability: ability, show_owner: show_owner).as_json
    end
  end

  def initialize(garden, plantings:, ability:, show_owner: true)
    @garden = garden
    @plantings = plantings
    @ability = ability
    @show_owner = show_owner
  end

  def as_json(*)
    {
      id: @garden.id, name: @garden.name, slug: @garden.slug, active: @garden.active,
      url: routes.garden_path(@garden), image_url: image_url,
      owner: owner, can_edit: can?(:edit, @garden), actions: garden_actions,
      perennials: @plantings.select { |planting| planting.crop.perennial? }.map { |planting| perennial(planting) },
      annuals: @plantings.select { |planting| planting.crop.annual? }.map { |planting| annual(planting) }
    }
  end

  private

  def routes
    Rails.application.routes.url_helpers
  end

  def can?(*)
    @ability.can?(*)
  end

  def owner
    return unless @show_owner

    { login_name: @garden.owner.login_name, url: routes.member_path(@garden.owner) }
  end

  # Photos give a full URL; the placeholder is an asset name.
  def image_url
    path = garden_image_path(@garden)
    path.start_with?('http') ? path : ActionController::Base.helpers.image_path(path)
  end

  # options: method (for non-GET links, as jquery_ujs data-method), confirm, divider.
  def action(key, label, href, **options)
    { key: key, label: label, href: href, **options }.compact
  end

  # The same items, in the same order, as gardens/_actions.
  def garden_actions
    return [] unless can?(:edit, @garden)

    actions = @garden.active ? active_garden_actions : [inactive_garden_action]
    actions << action(:edit, I18n.t('buttons.edit'), routes.edit_garden_path(@garden))
    actions << photo_action(@garden)
    actions << delete_action
    actions.compact
  end

  def active_garden_actions
    [
      action(:plant, I18n.t('buttons.plant_something_here'), routes.new_planting_path(garden_id: @garden.id)),
      action(:plan, I18n.t('buttons.new_activity'), routes.new_activity_path(garden_id: @garden.id)),
      action(:deactivate, I18n.t('buttons.mark_as_inactive'), routes.garden_path(@garden, garden: { active: 0 }),
             method: :put, confirm: I18n.t('gardens.confirm_deactivate'))
    ]
  end

  def inactive_garden_action
    action(:activate, I18n.t('buttons.mark_as_active'), routes.garden_path(@garden, garden: { active: 1 }),
           method: :put)
  end

  def photo_action(model)
    return unless can?(:edit, model) && can?(:create, Photo)

    type = ActiveModel::Name.new(model.class).to_s.downcase
    action(:photo, I18n.t('buttons.add_photo'), routes.new_photo_path(id: model.id, type: type))
  end

  def delete_action
    return unless can?(:destroy, @garden)

    action(:delete, I18n.t('buttons.delete'), routes.garden_path(@garden), method:  :delete,
                                                                           confirm: I18n.t('gardens.confirm_delete'),
                                                                           divider: true)
  end

  def crop_chip(planting)
    crop = planting.crop
    { name: crop.name, icon_url: crop.svg_icon.present? ? routes.crop_path(crop, format: 'svg') : nil }
  end

  def perennial(planting)
    { id: planting.id, url: routes.planting_path(planting), crop: crop_chip(planting) }
  end

  def annual(planting)
    {
      id: planting.id, url: routes.planting_path(planting), crop: crop_chip(planting),
      planted_at: planting.planted_at, percentage_grown: planting.percentage_grown,
      finish_predicted_label: finish_label(planting), progress_note: progress_note(planting),
      badges: badges(planting), actions: planting_actions(planting)
    }
  end

  # "Mar 2026", as plantings/_progress shows it.
  def finish_label(planting)
    date = planting.finish_predicted_at
    "#{I18n.t('date.abbr_month_names')[date.month]} #{date.year}" if date
  end

  # Shown instead of a progress bar when there is nothing to predict from.
  def progress_note(planting)
    if planting.planted_at.blank?
      'set "planted" date to allow predictions'
    elsif planting.percentage_grown.blank?
      "not enough data on #{planting.crop} to predict"
    end
  end

  # The same logic as plantings/_badges.
  def badges(planting)
    return [] if planting.finished?

    result = []
    result << finish_badge(planting) if planting.finish_is_predicatable?
    result << harvest_badge(planting) unless planting.super_late?
    result.compact
  end

  def finish_badge(planting)
    if planting.super_late?
      { kind: 'super_late', label: I18n.t('plantings.badges.super_late') }
    elsif planting.late?
      { kind: 'late', label: I18n.t('plantings.badges.late_finishing') }
    end
  end

  def harvest_badge(planting)
    if planting.harvest_time?
      { kind: 'harvest', label: I18n.t('label.harvesting_now'), title: 'Planting is ready for harvesting now' }
    elsif planting.before_harvest_time?
      weeks = ((planting.first_harvest_predicted_at - Time.zone.today).to_i / 7.0).round
      { kind: 'harvest_soon', label: I18n.t('label.weeks_until_harvest', number: weeks),
        title: 'Predicted weeks until harvest' }
    end
  end

  # The same items, in the same order, as plantings/_quick_actions.
  def planting_actions(planting)
    return [] unless can?(:edit, planting)

    actions = [
      action(:view, I18n.t('buttons.view'), routes.planting_path(planting)),
      action(:edit, I18n.t('buttons.edit'), routes.edit_planting_path(planting)),
      photo_action(planting)
    ]
    actions.concat(active_planting_actions(planting)) if planting.active
    actions.compact
  end

  def active_planting_actions(planting)
    [
      action(:finish, I18n.t('buttons.mark_as_finished'),
             routes.planting_path(slug: planting.slug, planting: { finished: 1 }), method: :put),
      (action(:harvest, I18n.t('buttons.record_harvest'), routes.new_planting_harvest_path(planting_slug: planting.slug)) if can?(:create,
                                                                                                                                  Harvest)),
      (action(:seeds, I18n.t('buttons.save_seeds'), routes.new_planting_seed_path(planting_slug: planting.slug)) unless planting.failed?)
    ].compact
  end
end

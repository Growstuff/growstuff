# frozen_string_literal: true

# A planting as a chip with a menu, for the React cards: its crop's name and icon,
# where it is, and the menu items you may use on it. The server decides the
# links and permissions, and React just draws them.
class PlantingChipSerializer
  include CardActions

  def initialize(planting, ability:)
    @planting = planting
    @ability = ability
  end

  def as_json(*)
    {
      id: @planting.id, url: routes.planting_path(@planting), crop: crop_chip, can_edit: can?(:edit, @planting),
      actions: planting_actions
    }
  end

  private

  def crop_chip
    crop = @planting.crop
    { name: crop.name, icon_url: crop.svg_icon.present? ? routes.crop_path(crop, format: 'svg') : nil }
  end

  # The same items, in the same order, as plantings/_quick_actions: finishing
  # goes last, below a divider, as it takes the planting off the list.
  def planting_actions
    return [] unless can?(:edit, @planting)

    actions = [
      action(:view, I18n.t('buttons.view'), routes.planting_path(@planting)),
      action(:edit, I18n.t('buttons.edit'), routes.edit_planting_path(@planting)),
      photo_action(@planting)
    ]
    actions.concat(active_planting_actions) if @planting.active
    actions.compact
  end

  def harvest_action
    return unless can?(:create, Harvest)

    action(:harvest, I18n.t('buttons.record_harvest'), routes.new_planting_harvest_path(planting_slug: @planting.slug))
  end

  def active_planting_actions
    [
      harvest_action,
      (action(:seeds, I18n.t('buttons.save_seeds'), routes.new_planting_seed_path(planting_slug: @planting.slug)) unless @planting.failed?),
      action(:finish, I18n.t('buttons.mark_as_finished'),
             routes.planting_path(slug: @planting.slug, planting: { finished: 1 }), method: :put, divider: true)
    ].compact
  end
end

# frozen_string_literal: true

module PlantingsHelper
  def display_finished(planting)
    if planting.finished_at.present?
      planting.finished_at
    elsif planting.finished
      "Yes (no date specified)"
    else
      "(no date specified)"
    end
  end

  def display_planted_from(planting)
    planting.planted_from.presence || "not specified"
  end

  def display_planting_quantity(planting)
    planting.quantity.presence || "not specified"
  end

  def display_planting(planting)
    if planting.quantity.to_i > 0 && planting.planted_from.present?
      "#{planting.owner} planted #{pluralize(planting.quantity, planting.planted_from)}."
    elsif planting.quantity.to_i > 0
      "#{planting.owner} planted #{pluralize(planting.quantity, 'unit')}."
    elsif planting.planted_from.present?
      "#{planting.owner} planted #{planting.planted_from.pluralize}."
    else
      "#{planting.owner} planted #{planting.crop}."
    end
  end

  def days_from_now_to_finished(planting)
    return unless planting.finish_is_predicatable?

    (planting.finish_predicted_at - Time.zone.today).to_i
  end

  def days_from_now_to_first_harvest(planting)
    return unless planting.planted_at.present? && planting.first_harvest_predicted_at.present?

    (planting.first_harvest_predicted_at - Time.zone.today).to_i
  end

  # Returns a list of gardens the planting can be transplanted to
  # based on the planting's owner.
  def transplantable_gardens_by_owner(planting)
    @transplantable_gardens ||= {}
    cache_key = planting.id || planting.object_id
    @transplantable_gardens[cache_key] ||= begin
      garden_ids = planting.owner.gardens.select(:id).to_a + GardenCollaborator.where(member_id: planting.owner.id).select(:garden_id).to_a

      Garden.active.where.not(id: planting.garden_id).where(id: garden_ids)
    end
  end

  def days_from_now_to_last_harvest(planting)
    return unless planting.planted_at.present? && planting.last_harvest_predicted_at.present?

    (planting.last_harvest_predicted_at - Time.zone.today).to_i
  end

  def planting_classes(planting)
    classes = []
    classes << 'planting-growing' if planting.growing?
    classes << 'planting-finished' if planting.finished?
    classes << 'planting-harvest-time' if planting.harvest_time?
    classes << 'planting-late' if planting.late?
    classes << 'planting-super-late' if planting.super_late?
    classes.join(' ')
  end

  def planting_status(planting)
    if planting.crop.perennial
      t 'planting.status.perennial'
    elsif planting.finished?
      t 'planting.status.finished'
    elsif !planting.finish_is_predicatable?
      t 'planting.status.not_enough_data'
    elsif planting.harvest_time?
      t 'planting.status.harvesting'
    elsif planting.late?
      t 'planting.status.late'
    elsif planting.growing?
      t 'planting.status.growing'
    elsif !planting.planted?
      t 'planting.status.not planted'
    else
      t 'planting.status.unknown'
    end
  end

  # What the PlantingActions island needs: the planting itself, the menu items
  # (the server still decides labels, links and permissions), and the icons the
  # dialogs show in their headers. Mirrors GardenCardSerializer#planting_actions
  # so the menu is the same on a card and on the planting's own page.
  def planting_actions_props(planting)
    {
      planting:         {
        id:         planting.id,
        url:        planting_path(planting),
        # The finish and harvest dialogs need these: neither may happen before
        # the planting was planted, and the server's today is the one that
        # counts, not the browser's.
        planted_at: planting.planted_at,
        today:      Time.zone.today,
        crop:       { name:     planting.crop.name,
                      icon_url: planting.crop.svg_icon.present? ? crop_path(planting.crop, format: 'svg') : nil }
      },
      actions:          planting_menu_actions(planting),
      harvest_icon_url: image_path('icons/harvest.svg'),
      seed_icon_url:    image_path('icons/seeds.svg'),
      photo_icon_url:   image_path('icons/photo.svg'),
      finish_icon_url:  image_path('icons/finish.svg')
    }
  end

  # Edit, add photo, the state changes, then delete last below a divider.
  def planting_menu_actions(planting)
    return [] unless can?(:edit, planting)

    actions = [{ key: 'edit', label: t('buttons.edit'), href: edit_planting_path(planting) }]
    if can?(:create, Photo)
      actions << { key: 'photo', label: t('buttons.add_photo'),
                   href: new_photo_path(id: planting.id, type: 'planting') }
    end
    actions.concat(active_planting_menu_actions(planting)) if planting.active
    actions << planting_delete_action(planting)
    actions.compact
  end

  def active_planting_menu_actions(planting)
    actions = []
    if can?(:create, Harvest)
      actions << { key: 'harvest', label: t('buttons.record_harvest'),
                   href: new_planting_harvest_path(planting_slug: planting.slug) }
    end
    unless planting.failed?
      actions << { key: 'seeds', label: t('buttons.save_seeds'),
                   href: new_planting_seed_path(planting_slug: planting.slug) }
    end
    actions << { key: 'finish', label: t('buttons.mark_as_finished'),
                 href: planting_path(slug: planting.slug, planting: { finished: 1 }), method: 'put' }
    if can?(:transplant, planting) && transplantable_gardens_by_owner(planting).any?
      actions << { key: 'transplant', label: 'Transplant', href: '#transplant-modal' }
    end
    actions
  end

  def planting_delete_action(planting)
    return unless can?(:destroy, planting)

    { key: 'delete', label: t('buttons.delete'), href: planting_path(planting),
      method: 'delete', confirm: t('are_you_sure'), divider: true }
  end
end

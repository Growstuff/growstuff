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
    planting.planted_from.present? ? planting.planted_from : "not specified"
  end

  def display_planting_quantity(planting)
    planting.quantity.present? ? planting.quantity : "not specified"
  end

  def display_planting(planting)
    if planting.quantity.to_i > 0 && planting.planted_from.present?
      "#{planting.owner} planted #{pluralize(planting.quantity, planting.planted_from)}."
    elsif planting.quantity.to_i > 0
      "#{planting.owner} planted #{pluralize(planting.quantity, 'unit')}."
    elsif planting.planted_from.present?
      "#{planting.owner} planted #{planting.planted_from.pluralize}."
    else
      "#{planting.owner}."
    end
  end

  def plantings_active_tickbox_path(owner, show_all)
    show_inactive_tickbox_path('plantings', owner, show_all)
  end

  def days_from_now_to_finished(planting)
    return unless planting.finish_is_predicatable?
    (planting.finish_predicted_at - Time.zone.today).to_i
  end

  def days_from_now_to_first_harvest(planting)
    return unless planting.planted_at.present? && planting.first_harvest_predicted_at.present?
    (planting.first_harvest_predicted_at - Time.zone.today).to_i
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
end

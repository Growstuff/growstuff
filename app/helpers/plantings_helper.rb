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
end

module PlantingsHelper
  def display_days_before_maturity(planting)
    # First try to calc from finished/finished_at
    if planting.finished? || planting.finished_at.present?
      planting.days_until_finished.to_s
    # then try to calc from planted at + maturity
    elsif planting.planted_at.present? && planting.days_before_maturity.present?
      planting.days_until_mature.to_s
    else
      "unknown"
    end
  end

  def display_finished(planting)
    if !planting.finished_at.nil?
      planting.finished_at
    elsif planting.finished
      "Yes (no date specified)"
    else
      "(no date specified)"
    end
  end

  def display_planted_from(planting)
    !planting.planted_from.blank? ? planting.planted_from : "not specified"
  end

  def display_planting_quantity(planting)
    !planting.quantity.blank? ? planting.quantity : "not specified"
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
end

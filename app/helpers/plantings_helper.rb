module PlantingsHelper
  def display_days_before_maturity(planting)
    if planting.finished?
      "0"
    elsif !planting.finished_at.nil?
      ((p = planting.finished_at - Date.current).to_i) <= 0 ? "0" : p.to_i.to_s
    elsif planting.planted_at.nil? || planting.days_before_maturity.nil?
      "unknown"
    else
      ((p = (planting.planted_at + planting.days_before_maturity) - Date.current).to_i <= 0) ? "0" : p.to_i.to_s
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

module PlantingsHelper

  def display_planting(planting)
    if planting.quantity.to_i > 0 && planting.planted_from.present?
      return "#{planting.owner} planted #{pluralize(planting.quantity, planting.planted_from)}."
    elsif planting.quantity.to_i > 0
      return "#{planting.owner} planted #{pluralize(planting.quantity, 'unit')}."
    elsif planting.planted_from.present?
      return "#{planting.owner} planted #{planting.planted_from.pluralize}."
    else
      return "#{planting.owner}."
    end
  end

end
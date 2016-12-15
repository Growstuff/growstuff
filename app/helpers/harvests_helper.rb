module HarvestsHelper
  def display_quantity(harvest)
    human_quantity = display_human_quantity(harvest)
    weight = display_weight(harvest)

    if human_quantity && weight
      return "#{human_quantity}, weighing #{weight}"
    elsif human_quantity
      return human_quantity
    elsif weight
      return weight
    else
      return 'not specified'
    end
  end

  def display_human_quantity(harvest)
    if !harvest.quantity.blank? && harvest.quantity > 0
      if harvest.unit == 'individual' # just the number
        number_to_human(harvest.quantity, strip_insignificant_zeros: true)
      elsif !harvest.unit.blank? # pluralize anything else
        pluralize(number_to_human(harvest.quantity, strip_insignificant_zeros: true), harvest.unit)
      else
        "#{number_to_human(harvest.quantity, strip_insignificant_zeros: true)} #{harvest.unit}"
      end
    end
  end

  def display_weight(harvest)
    return if harvest.weight_quantity.blank? || harvest.weight_quantity <= 0
    "#{number_to_human(harvest.weight_quantity, strip_insignificant_zeros: true)} #{harvest.weight_unit}"
  end

  def display_harvest_description(harvest)
    return "No description provided." if harvest.description.empty?
    harvest.description
  end
end

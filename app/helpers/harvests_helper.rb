module HarvestsHelper

  def display_quantity(harvest)
    human_quantity = display_human_quantity(harvest)
    weight = display_weight(harvest)

    if human_quantity && weight
      "#{human_quantity}, weighing #{weight}"
    elsif human_quantity
      human_quantity
    elsif weight
      weight
    else
      'not specified'
    end
  end

  def display_human_quantity(harvest)
    if ! harvest.quantity.blank? && harvest.quantity > 0
      if harvest.unit == 'individual' # just the number
        number_to_human(harvest.quantity, strip_insignificant_zeros: true)
      elsif ! harvest.unit.blank? # pluralize anything else
        pluralize(number_to_human(harvest.quantity, strip_insignificant_zeros: true), harvest.unit)
      else
        "#{number_to_human(harvest.quantity, strip_insignificant_zeros: true)} #{harvest.unit}"
      end
    else
      nil
    end
  end

  def display_weight(harvest)
    if ! harvest.weight_quantity.blank? && harvest.weight_quantity > 0
      "#{number_to_human(harvest.weight_quantity, strip_insignificant_zeros: true)} #{harvest.weight_unit}"
    else
      nil
    end
  end

  def display_harvest_description(harvest)
    if harvest.description.empty?
      "No description provided."
    else
      harvest.description
    end
  end

end

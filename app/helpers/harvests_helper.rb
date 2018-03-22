module HarvestsHelper
  def display_quantity(harvest)
    human_quantity = display_human_quantity(harvest)
    weight = display_weight(harvest)

    return "#{human_quantity}, weighing #{weight}" if human_quantity && weight
    return human_quantity if human_quantity
    return weight if weight

    'not specified'
  end

  def display_human_quantity(harvest)
    return unless harvest.quantity.present? && harvest.quantity > 0

    if harvest.unit == 'individual' # just the number
      number_to_human(harvest.quantity, strip_insignificant_zeros: true)
    elsif harvest.unit.present? # pluralize anything else
      pluralize(number_to_human(harvest.quantity, strip_insignificant_zeros: true), harvest.unit)
    else
      "#{number_to_human(harvest.quantity, strip_insignificant_zeros: true)} #{harvest.unit}"
    end
  end

  def display_weight(harvest)
    return if harvest.weight_quantity.blank? || harvest.weight_quantity <= 0
    "#{number_to_human(harvest.weight_quantity, strip_insignificant_zeros: true)} #{harvest.weight_unit}"
  end

  def display_harvest_description(harvest)
    if harvest.description.nil?
      "no description provided."
    else
      truncate(harvest.description, length: 50, separator: ' ', omission: '... ') do
        link_to "Read more", harvest_path(harvest)
      end
    end
  end
end

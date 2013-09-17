module HarvestsHelper

def display_quantity(harvest)
  if ! harvest.quantity.blank?
    if harvest.unit == 'individual'
      number_to_human(harvest.quantity, :strip_insignificant_zeros => true)
    elsif harvest.unit == 'bunch'
      return pluralize(number_to_human(harvest.quantity, :strip_insignificant_zeros => true), harvest.unit)
    else
      return "#{number_to_human(harvest.quantity, :strip_insignificant_zeros => true)} #{harvest.unit}"
    end
  else
    return 'not specified'
  end
end

end

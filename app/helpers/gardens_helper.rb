module GardensHelper
  def display_garden_description(garden)
    return "" unless garden.description.present?
    truncate(garden.description, length: 130, separator: ' ', omission: '... ') do
      link_to "Read more", garden_path(garden)
    end
  end

  def display_garden_plantings(plantings)
    return "" unless plantings.present?
    output = '<ul class="garden-plantings">'
    plantings.first(6).each do |planting|
      output += "<li>"
      output += "#{planting.quantity} " if planting.quantity.present?
      output += link_to planting.crop.name, planting.crop
      output += '</li>'
    end
    output += '</ul>'
    output.html_safe
  end
end

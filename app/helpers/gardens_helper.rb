# frozen_string_literal: true

module GardensHelper
  def display_garden_description(garden)
    if garden.description.nil?
      "no description provided."
    else
      truncate(garden.description, length: 130, separator: ' ', omission: '... ') do
        link_to "Read more", garden_path(garden)
      end
    end
  end

  def display_garden_name(garden)
    truncate(garden.name, length: 50, separator: ' ', omission: '... ')
  end

  def display_garden_plantings(plantings)
    if plantings.blank?
      "None"
    else
      output = '<ul class="plantings">'
      plantings.each do |planting|
        output += "<li>"
        output += planting.quantity.nil? ? "0 " : "#{planting.quantity} "
        output += link_to planting.crop.name, planting.crop
        output += ", planted on #{planting.planted_at}</li>"
      end
      output += '</ul>'
      output.html_safe

    end
  end
end

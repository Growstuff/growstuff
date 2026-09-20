# frozen_string_literal: true

module GardensHelper
  # Props for the GardenCards React island: a card per garden, plus the icon to
  # use for crops that have none of their own.
  def garden_cards_props(gardens, owner: nil)
    {
      gardens:          GardenCardSerializer.collection(gardens, ability: current_ability, show_owner: owner.blank?),
      default_icon_url: image_path('icons/planting.svg'),
      spade_icon_url:   image_path('spade-marker.svg'),
      harvest_icon_url: image_path('icons/harvest.svg')
    }
  end

  # "2022–2024 · 12 plantings": when an inactive garden was in use, by its plantings.
  def garden_history_summary(garden)
    plantings = garden.plantings.to_a
    years = plantings.filter_map { |planting| planting.planted_at&.year }
    years = [garden.created_at.year] if years.empty?
    range = years.min == years.max ? years.min.to_s : "#{years.min}–#{years.max}"
    "#{range} · #{pluralize(plantings.size, 'planting')}"
  end

  def display_garden_description(garden)
    if garden.description.nil?
      "no description provided."
    else
      truncate(garden.description, length: 130, separator: ' ', omission: '... ') do
        link_to "Read more", garden_path(garden)
      end
    end
  end

  # TODO: Not used?
  def display_garden_name(garden)
    truncate(garden.name, length: 50, separator: ' ', omission: '... ')
  end

  # TODO: Only used by specs?
  def display_garden_plantings(plantings)
    if plantings.blank?
      "None"
    else
      output = '<ul class="plantings">'
      plantings.each do |planting|
        output += "<li>"
        output += planting.quantity.nil? ? "0 " : "#{planting.quantity} "
        output += link_to planting.display_name, planting.crop
        output += ", planted on #{planting.planted_at}</li>"
      end
      output += '</ul>'
      output.html_safe

    end
  end
end

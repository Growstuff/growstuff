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

  def gardens_active_tickbox_path(owner, show_all)
    all = show_all ? '' : 1
    if owner
      gardens_by_owner_path(owner: owner.slug, all: all)
    else
      gardens_path(all: all)
    end
  end

  def display_garden_name(garden)
    truncate(garden.name, length: 50, separator: ' ', omission: '... ')
  end

  def display_garden_plantings(plantings)
    if plantings.blank?
      "None"
    else
      output = ""
      plantings.first(2).each do |planting|
        output += "<li>"
        output += planting.quantity.nil? ? "0 " : "#{planting.quantity} "
        output += link_to planting.crop.name, planting.crop
        output += ", planted on #{planting.planted_at}</li>"
      end
      output.html_safe
    end
  end
end

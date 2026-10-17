# frozen_string_literal: true

module GardensHelper
  # Props for the GardenCards React island: a card per garden, plus the icon to
  # use for crops that have none of their own.
  def garden_cards_props(gardens, owner: nil)
    {
      gardens:          GardenCardSerializer.collection(gardens, ability: current_ability, show_owner: owner.blank?),
      default_icon_url: image_path('icons/planting.svg'),
      spade_icon_url:   image_path('spade-marker.svg'),
      harvest_icon_url: image_path('icons/harvest.svg'),
      seed_icon_url:    image_path('icons/seeds.svg'),
      photo_icon_url:   image_path('icons/photo.svg'),
      finish_icon_url:  image_path('icons/finish.svg')
    }
  end

  # The plantings currently in a nursery, newest sown first.
  def nursery_seedlings(nursery)
    return [] unless nursery

    nursery.plantings.current.includes(crop: :parent).order(planted_at: :desc, id: :desc).to_a
  end

  # What has been sown, as [day, plantings] pairs, newest day first.
  def nursery_sown_groups(seedlings)
    seedlings.reject(&:planned?).group_by { |seedling| seedling.planted_at || seedling.created_at.to_date }
      .sort_by(&:first).reverse
  end

  # What is planned but not sown yet, soonest first.
  def nursery_planned(seedlings)
    seedlings.select(&:planned?).sort_by(&:planted_at)
  end

  # "Today", or "Mon 12 Oct · 5 days ago".
  def nursery_day_label(day)
    today = Time.zone.today
    return 'Today' if day == today

    ago = (today - day).to_i
    "#{l(day, format: '%a %-d %b')} · #{ago == 1 ? 'yesterday' : "#{ago} days ago"}"
  end

  # "12 seedlings", counting each plant, or that there are none sown yet.
  def nursery_seedling_count(seedlings)
    sown = seedlings.reject(&:planned?)
    return 'No seedlings yet' if sown.empty?

    pluralize(sown.sum { |seedling| seedling.quantity || 1 }, 'seedling')
  end

  # The sow seeds dialog's props: the nursery, the member's other gardens to sow
  # straight into, and their seed packets to sow from.
  def nursery_planter_props(nursery)
    owner = nursery.owner
    {
      garden:      { id: nursery.id, name: nursery.name },
      gardens:     owner.gardens.active.not_nurseries.order_by_name.map { |garden| { id: garden.id, name: garden.name } },
      seeds:       owner.seeds.active.includes(:crop, :photos).order(created_at: :desc).limit(200).map { |seed| seed_packet_props(seed) },
      label:       'Sow seeds',
      buttonClass: 'btn btn-primary'
    }
  end

  # A seed packet for the sow dialog, with the photo of it if there is one, as
  # that is what tells two packets of the same crop apart.
  def seed_packet_props(seed)
    photo = seed.photos.first
    { id: seed.id, crop_id: seed.crop_id, crop_slug: seed.crop.slug, name: seed.crop_name, quantity: seed.quantity,
      heirloom: seed.heirloom, saved: l(seed.created_at.to_date, format: '%-d %b %Y'),
      plant_before: seed.plant_before&.iso8601, photo_url: (thumbnail_url(photo) if photo) }
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

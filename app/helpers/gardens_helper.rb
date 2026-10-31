# frozen_string_literal: true

module GardensHelper
  # The line under a garden's name: where it is, what kind, how big, and how far
  # from the person looking, whichever of those are known.
  def garden_details(garden)
    location = link_to(garden.location, place_path(garden.location)) if garden.location.present?
    area = pluralize(number_with_precision(garden.area, precision: 2, strip_insignificant_zeros: true), garden.area_unit) if garden.area.present?
    safe_join([location, garden.garden_type&.name, area, garden_distance(garden)].compact, ' · ')
  end

  # A temperature as degrees, or that it is not known.
  def temperature_text(celsius)
    celsius.present? ? "#{celsius.round(1)}°C" : t('gardens.about.temperature_unknown')
  end

  # The garden types to choose from, as name and id.
  def garden_type_options
    GardenType.order(:name).pluck(:name, :id)
  end

  # Props for the GardenCards React island: a card per garden, plus the icon to
  # use for crops that have none of their own.
  def garden_cards_props(gardens, owner: nil)
    {
      gardens:          GardenCardSerializer.collection(gardens, ability: card_ability, show_owner: owner.blank?),
      default_icon_url: image_path('icons/planting.svg'),
      spade_icon_url:   image_path('spade-marker.svg'),
      harvest_icon_url: image_path('icons/harvest.svg'),
      seed_icon_url:    image_path('icons/seeds.svg'),
      photo_icon_url:   image_path('icons/photo.svg'),
      finish_icon_url:  image_path('icons/finish.svg')
    }
  end

  # The permissions the cards on this page ask about, each worked out once.
  def card_ability
    @card_ability ||= CachedAbility.new(current_ability)
  end

  # How far the signed-in member is from a garden, such as "about 4 km from
  # you". Nothing when either has no location, or it is the member's own garden.
  def garden_distance(garden)
    return if current_member.blank? || garden.owner == current_member
    return unless current_member.latitude && garden.latitude

    km = Geocoder::Calculations.distance_between(
      [current_member.latitude, current_member.longitude],
      [garden.latitude, garden.longitude], units: :km
    )
    t('gardens.show.km_from_you', km: km.round)
  end

  # What is currently in a nursery, newest sown first.
  def nursery_seedlings(nursery)
    return [] unless nursery

    nursery.plantings.current.includes({ crop: :parent }, :photos).order(planted_at: :desc, id: :desc).to_a
  end

  # What has been sown, as [[day, got as seedlings], plantings] pairs, newest
  # day first. Seedlings that were given or bought are a group of their own.
  def nursery_sown_groups(seedlings)
    seedlings
      .group_by { |seedling| [seedling.planted_at || seedling.created_at.to_date, seedling.planted_from == 'seedling'] }
      .sort_by { |(day, got), _| [day, got ? 0 : 1] }.reverse
  end

  # The bold line of a group: "Today", or "Mon 12 Oct".
  def nursery_day_title(day)
    day == Time.zone.today ? 'Today' : l(day, format: '%a %-d %b')
  end

  # The line under it: today's date, "5 days ago", or that they were got as seedlings.
  def nursery_day_subtitle(day, got)
    today = Time.zone.today
    return 'got as seedlings' if got
    return l(day, format: '%a %-d %b') if day == today

    ago = (today - day).to_i
    ago == 1 ? 'yesterday' : "#{ago} days ago"
  end

  # "12 seedlings", counting each plant, or that there are none sown yet.
  def nursery_seedling_count(seedlings)
    return 'No seedlings yet' if seedlings.empty?

    pluralize(seedlings.sum { |seedling| seedling.quantity || 1 }, 'seedling')
  end

  # The member's gardens that things can be sown or transplanted into.
  def nursery_gardens(nursery)
    nursery.owner.gardens.active.not_nurseries.order_by_name.map { |g| { id: g.id, name: g.name, slug: g.slug } }
  end

  # A batch's chip and menu, for the NurseryChip island, and how many there are.
  # "Transplant" is in the menu after "view", for batches that can be moved. You
  # don't harvest or save seeds from seedlings, so those aren't.
  def nursery_chip_props(seedling, gardens:)
    chip = PlantingChipSerializer.new(seedling, ability: card_ability).as_json.merge(slug: seedling.slug)
    {
      planting:         nursery_chip_with_transplant(chip, seedling, gardens),
      gardens:          gardens,
      default_icon_url: image_path('icons/planting.svg'),
      photo_icon_url:   image_path('icons/photo.svg'),
      detail:           ("\u00d7 #{seedling.quantity}" if seedling.quantity)
    }
  end

  def nursery_chip_with_transplant(chip, seedling, gardens)
    actions = chip[:actions].reject { |action| %i(harvest seeds).include?(action[:key]) }
    if gardens.any? && card_ability.can?(:transplant, seedling)
      actions.insert([1, actions.size].min, { key: :transplant, label: I18n.t('buttons.transplant'), href: planting_path(seedling) })
    end
    chip.merge(actions: actions)
  end

  # The sow seeds dialog's props: the nursery, the member's other gardens to sow
  # straight into, and their seed packets to sow from.
  def nursery_planter_props(nursery)
    owner = nursery.owner
    {
      garden:      { id: nursery.id, name: nursery.name },
      gardens:     nursery_gardens(nursery),
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

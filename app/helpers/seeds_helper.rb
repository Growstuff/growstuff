# frozen_string_literal: true

module SeedsHelper
  def display_seed_quantity(seed)
    if seed.quantity.nil?
      'seeds'
    else
      pluralize(seed.quantity, 'seed')
    end
  end

  def display_seed_description(seed)
    if seed.description.present?
      return truncate(seed.description, length: 130, separator: ' ', omission: '... ') do
        link_to "Read more", seed_path(seed)
      end
    end

    ''
  end

  # Kilometres from the signed-in member to a seed's owner, or nil when either
  # has no location.
  def seed_km(seed)
    return unless current_member&.latitude && seed.owner.latitude

    Geocoder::Calculations.distance_between(
      [current_member.latitude, current_member.longitude],
      [seed.owner.latitude, seed.owner.longitude], units: :km
    )
  end

  # How far away that is, such as "12 km".
  def seed_distance(seed)
    km = seed_km(seed)
    "#{km.round} km" if km
  end

  # Packets nearest the signed-in member first; those with no known distance
  # last, and ties in the order given.
  def nearest_first(packets)
    packets.sort_by.with_index { |seed, index| [seed_km(seed) || Float::INFINITY, index] }
  end

  SOURCE_LABELS = {
    'seed catalogue'                   => 'catalogue',
    'retail outlet'                    => 'retail outlet',
    'seed bank or similar institution' => 'seed bank',
    'traded from another person'       => 'traded',
    'my own seed saving'               => 'own saving'
  }.freeze

  # Where a packet came from, in the few words a packet has room for.
  def seed_source_label(source)
    SOURCE_LABELS[source]
  end

  # The year along the foot of a packet: a range for a pile, else when it was
  # saved or the year to sow it by.
  def seed_packet_rule(packets)
    years = packets.filter_map { |seed| (seed.saved_at || seed.plant_before)&.year }
    return if years.empty?
    return years.minmax.uniq.join(' – ') if packets.size > 1

    seed = packets.first
    seed.saved_at ? "saved #{years.first}" : "sow by #{years.first}"
  end

  # What the SeedStack island needs to draw a pile of packets of one variety,
  # open or closed, and to link each packet to its page.
  def seed_stack_props(packets, open_crop_id: nil, show_owner: false)
    first = packets.first
    crop = first.crop
    {
      crop:      { name: crop.name, path: crop_path(crop) },
      count:     packets.size,
      image_url: seed_image_url(first),
      heirloom:  (first.heirloom unless first.heirloom == 'unknown'),
      rule:      seed_packet_rule(packets),
      open:      crop.id == open_crop_id,
      owner:     (seed_owner_props(first) if show_owner),
      packets:   packets.map { |seed| seed_stack_packet_props(seed) }
    }
  end

  # Who a packet belongs to, for the avatar beside it.
  def seed_owner_props(seed)
    owner = seed.owner
    where = [owner.location&.split(',')&.first, seed_distance(seed)].compact_blank.join(' · ')
    {
      name:       owner.login_name,
      path:       member_path(owner),
      avatar_url: avatar_uri(owner, 32),
      label:      [owner.login_name, where].compact_blank.join(' · ')
    }
  end

  def seed_stack_packet_props(seed)
    past = seed.plant_before.present? && seed.plant_before < Time.zone.today
    {
      id:        seed.id,
      name:      seed.crop_name,
      path:      seed_path(slug: seed.slug),
      edit_path: (edit_seed_path(slug: seed.slug) if can?(:edit, seed)),
      image_url: seed_image_url(seed),
      heirloom:  (seed.heirloom unless seed.heirloom == 'unknown'),
      when:      seed_packet_when(seed),
      detail:    [(pluralize(seed.quantity, 'seed') if seed.quantity), seed_sharing(seed)].compact.join(' · '),
      rule:      seed_packet_sow_by(seed, past),
      past:
    }
  end

  def seed_image_url(seed)
    seed.thumbnail_url || image_path(placeholder_image)
  end

  # When a packet was saved or traded for, the way the design words it.
  def seed_packet_when(seed)
    date = seed.saved_at || seed.created_at.to_date
    if seed.source == 'traded from another person'
      "traded #{date.strftime('%b %Y')}"
    elsif seed.saved_at
      "saved #{date.strftime('%-d %b %Y')}"
    else
      seed_source_label(seed.source) || "added #{date.strftime('%-d %b %Y')}"
    end
  end

  def seed_sharing(seed)
    seed.tradable ? "shared #{seed.tradable_to}" : 'not shared'
  end

  def seed_packet_sow_by(seed, past)
    return unless seed.plant_before

    past ? "past sow-by #{seed.plant_before.year}" : "sow by #{seed.plant_before.year}"
  end
end

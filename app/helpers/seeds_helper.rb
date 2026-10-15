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

  # Who a packet belongs to, and where, for the avatar beside it.
  def seed_owner_label(seed)
    owner = seed.owner
    [owner.login_name, owner.location&.split(',')&.first, seed_distance(seed)].compact_blank.join(' · ')
  end

  # A shelf's seeds as piles of packets: on someone's own shelf one pile is a
  # variety, on everyone's it is one gardener's packets of a variety, nearest
  # gardener first. Ties keep the order given.
  def seed_stacks(seeds, by_owner: false)
    packets = seeds.sort_by { |seed| [seed.crop_name.downcase, seed.created_at] }
    return packets.group_by(&:crop_id).values unless by_owner

    nearest = packets.sort_by.with_index { |seed, index| [seed_km(seed) || Float::INFINITY, index] }
    nearest.group_by { |seed| [seed.owner_id, seed.crop_id] }.values
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

  # What the SeedStack island needs to draw a pile of packets of one variety
  # and to link each packet to its page.
  def seed_stack_props(packets, show_owner: false)
    first = packets.first
    {
      crop:      { name: first.crop.name, path: crop_path(first.crop) },
      count:     packets.size,
      image_url: seed_image_url(first),
      heirloom:  first.heirloom_kind,
      rule:      seed_packet_rule(packets),
      owner:     (seed_owner_props(first) if show_owner),
      packets:   packets.map { |seed| seed_stack_packet_props(seed) }
    }
  end

  def seed_owner_props(seed)
    {
      name:       seed.owner.login_name,
      path:       member_path(seed.owner),
      avatar_url: avatar_uri(seed.owner, 32),
      label:      seed_owner_label(seed)
    }
  end

  def seed_stack_packet_props(seed)
    {
      id:        seed.id,
      name:      seed.crop_name,
      path:      seed_path(slug: seed.slug),
      edit_path: (edit_seed_path(slug: seed.slug) if can?(:edit, seed)),
      image_url: seed_image_url(seed),
      heirloom:  seed.heirloom_kind,
      when:      seed_packet_when(seed),
      detail:    [(pluralize(seed.quantity, 'seed') if seed.quantity), seed_sharing(seed)].compact.join(' · '),
      rule:      seed_packet_sow_by(seed),
      past:      seed.past_sow_by?
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

  def seed_packet_sow_by(seed)
    return unless seed.plant_before

    year = seed.plant_before.year
    seed.past_sow_by? ? "past sow-by #{year}" : "sow by #{year}"
  end

  # A pill that narrows or reorders the seeds shown, filled when it is the
  # choice in force. Always back to the first page. `css_class` nil for the
  # joined buttons, which are styled by what holds them.
  def seed_choice_link(label, active, css_class: 'seed-chip', **url_params)
    link_to label, url_for(**url_params, page: nil), class: [css_class, ('active' if active)].compact
  end

  # The chips under the toolbar: [label, url params, whether it is chosen].
  def seed_filter_chips(everyone:)
    from = params[:from]
    if everyone
      [['Anywhere', { from: nil, within: nil }, from.blank? && params[:within].blank?],
       *seed_distance_chips,
       ['Heirloom only', { from: 'heirloom' }, from == 'heirloom'],
       ['Saved by the gardener', { from: 'own' }, from == 'own']]
    else
      [['All', { from: nil, tradeable_to: nil }, from.blank? && params[:tradeable_to].blank?],
       ['My own saving', { from: 'own' }, from == 'own'],
       ['Bought', { from: 'bought' }, from == 'bought'],
       ['Traded from a person', { from: 'traded' }, from == 'traded'],
       ['Heirloom only', { from: 'heirloom' }, from == 'heirloom'],
       ['Shared with others', { from: 'shared' }, from == 'shared']]
    end
  end

  def seed_distance_chips
    return [] unless current_member&.latitude

    [50, 10].map { |km| ["Within #{km} km", { within: km }, params[:within].to_i == km] }
  end
end

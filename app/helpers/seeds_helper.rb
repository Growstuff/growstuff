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

  # The words that say whose a packet is on a page of other people's seeds:
  # "Yours", or "from alex" with how far away they are when that is known.
  def seed_owner_tag(seed)
    return 'Yours' if seed.owner == current_member

    ["from #{seed.owner_login_name}", seed_distance(seed)].compact.join(' · ')
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
      label:      seed_owner_label(seed),
      tag:        seed_owner_tag(seed),
      yours:      seed.owner == current_member
    }
  end

  def seed_stack_packet_props(seed)
    {
      id:        seed.id,
      name:      seed.crop_name,
      path:      seed_path(slug: seed.slug),
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

  # The params that make up a view of the seed library: whose seeds (with the
  # path), what is filtered, and how it is shown.
  SEED_VIEW_PARAMS = %w(scope crop from heirloom shared planted gardener sow_month tradeable_to within past finished all group view).freeze

  # A link to the library you are looking at with some params changed, where
  # nil takes a param off, so choosing one thing keeps every other filter.
  # Pass `path` to look at someone else's seeds with the same filters.
  def seed_view_path(path: nil, **changes)
    kept = request.query_parameters.slice(*SEED_VIEW_PARAMS).merge(changes.stringify_keys).compact
    kept.delete('page')
    path ||= request.path
    kept.empty? ? path : "#{path}?#{kept.to_query}"
  end

  # What the SeedLibrary island needs: the controls, and the tabs and results to
  # start with. Which control is chosen it reads from the address.
  def seed_library_props(everyone:, crop_search:, search_crop:)
    {
      groups:      [%w(crop Crop), ['source', 'Where from'], ['year', 'Year saved'], ['use_by', 'Use by'], ['heirloom', 'Heirloom or hybrid']],
      filters:     seed_filter_groups(everyone:),
      sow_now:     "Sow now (#{Seed.sow_now_months.map { |month| Date::MONTHNAMES[month] }.join(' & ')})",
      gardeners:   (seed_friend_names if everyone),
      months:      Date::MONTHNAMES.compact.each_with_index.map { |name, index| [index + 1, name] },
      clear:       SEED_VIEW_PARAMS.excluding('scope', 'group', 'view').index_with { nil },
      crop_search:,
      crop:        search_crop && { name: search_crop.name, slug: search_crop.slug },
      placeholder: everyone ? 'Search all shared seeds by crop' : 'Search seeds by crop',
      tabs:        render('seeds/tabs'),
      html:        render('seeds/results')
    }
  end

  # The source chips: a label and the params it sets, where nil takes a param
  # off. Each kind of filter has its own param, so they combine: bought and
  # heirloom, near me and planted. Clicking a chosen chip takes it off again.
  def seed_source_chips
    [['All', { from: nil }],
     ['My own saving', { from: 'own' }],
     ['Seed catalogue', { from: 'catalogue' }],
     ['Retail outlet', { from: 'retail' }],
     ['Seed bank', { from: 'bank' }],
     ['Traded from a person', { from: 'traded' }]]
  end

  # Whether the gardener offered the packet to others, as against keeping it.
  def seed_sharing_chips
    [['Either', { shared: nil }],
     ['Shared for trading', { shared: 1 }]]
  end

  # The chips in their labelled groups. How far away only means something on
  # other people's seeds, and sharing only on a gardener's own: everyone's are
  # all shared.
  def seed_filter_groups(everyone:)
    chips = ->(list) { list.map { |label, params| { label:, params: } } }
    [{ label: 'Source', chips: chips.call(seed_source_chips) },
     ({ label: 'Distance', chips: chips.call(seed_distance_chips) } if everyone && current_member&.latitude),
     ({ label: 'Sharing', chips: chips.call(seed_sharing_chips) } unless everyone),
     { label: 'Heirloom or hybrid', chips: chips.call(seed_heirloom_chips) },
     { label: 'Planted', chips: chips.call(seed_planted_chips) }].compact
  end

  # The people a member follows, to suggest when looking for a gardener's seeds.
  def seed_friend_names
    current_member ? current_member.followed.order(:login_name).pluck(:login_name) : []
  end

  def seed_heirloom_chips
    [['Either', { heirloom: nil }],
     ['Heirloom only', { heirloom: 'heirloom' }],
     ['Hybrid only', { heirloom: 'hybrid' }]]
  end

  def seed_planted_chips
    [['Any', { planted: nil }],
     ['Planted', { planted: 'yes' }],
     ['Not planted yet', { planted: 'no' }]]
  end

  def seed_distance_chips
    [['Anywhere', { within: nil }], *[50, 10].map { |km| ["Within #{km} km", { within: km }] }]
  end
end

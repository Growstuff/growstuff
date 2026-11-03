# frozen_string_literal: true

# The filters of the seed library: which params there are, and the chips that
# set them.
module SeedFiltersHelper
  # The params that make up a view of the seed library: whose seeds (with the
  # path), what is filtered, and how it is shown.
  SEED_VIEW_PARAMS = (%w(scope crop finished all group view) + Seed::FILTER_PARAMS).freeze

  # A link to the library you are looking at with some params changed, where
  # nil takes a param off, so choosing one thing keeps every other filter.
  # Pass `path` to look at someone else's seeds with the same filters.
  def seed_view_path(path: nil, **changes)
    kept = request.query_parameters.slice(*SEED_VIEW_PARAMS).merge(changes.stringify_keys).compact
    kept.delete('page')
    path ||= request.path
    kept.empty? ? path : "#{path}?#{kept.to_query}"
  end

  # Every filter taken off, for a link that shows all the seeds.
  def seed_filters_off
    Seed::FILTER_PARAMS.index_with { nil }.symbolize_keys
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
    [['Source', seed_source_chips],
     (['Distance', seed_distance_chips] if everyone && current_member&.latitude),
     (['Sharing', seed_sharing_chips] unless everyone),
     ['Heirloom or hybrid', seed_heirloom_chips],
     ['Planted', seed_planted_chips]].compact.map do |label, chips|
      { label:, chips: chips.map { |chip_label, params| { label: chip_label, params: } } }
    end
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

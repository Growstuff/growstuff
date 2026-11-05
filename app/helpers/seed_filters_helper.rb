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
    path ||= request.path
    kept.empty? ? path : "#{path}?#{kept.to_query}"
  end

  # Every filter taken off, for a link that shows all the seeds.
  def seed_filters_off
    Seed::FILTER_PARAMS.index_with { nil }.symbolize_keys
  end

  # The source chips: a label and the params it sets, where nil takes a param
  # off. Each kind of filter has its own param, so they combine: catalogue
  # and heirloom, near me and planted. Clicking a chosen chip takes it off again.
  def seed_source_chips
    [['all', { from: nil }], ['own', { from: 'own' }], ['catalogue', { from: 'catalogue' }],
     ['retail', { from: 'retail' }], ['bank', { from: 'bank' }], ['traded', { from: 'traded' }]].map do |key, params|
      [t("seeds.library.sources.#{key}"), params]
    end
  end

  # Whether the gardener offered the packet to others, as against keeping it.
  def seed_sharing_chips
    [[t('seeds.library.sharing.either'), { shared: nil }],
     [t('seeds.library.sharing.shared'), { shared: 1 }]]
  end

  def seed_heirloom_chips
    [[t('seeds.library.heirloom.either'), { heirloom: nil }],
     [t('seeds.library.heirloom.heirloom'), { heirloom: 'heirloom' }],
     [t('seeds.library.heirloom.hybrid'), { heirloom: 'hybrid' }]]
  end

  def seed_planted_chips
    [[t('seeds.library.planted.any'), { planted: nil }],
     [t('seeds.library.planted.planted'), { planted: 'yes' }],
     [t('seeds.library.planted.not_planted'), { planted: 'no' }]]
  end

  def seed_distance_chips
    [[t('seeds.library.distance.anywhere'), { within: nil }],
     *[50, 10].map { |km| [t('seeds.library.distance.within', km:), { within: km }] }]
  end

  # The month names, in the language of the page.
  def seed_month_names
    t('seeds.library.months')
  end

  # "Sow now": this month, and next in the last days of it.
  def seed_sow_now_label
    this_month, next_month = Seed.sow_now_months.map { |month| seed_month_names[month - 1] }
    return t('seeds.library.sow_now.this_month', month: this_month) unless next_month

    t('seeds.library.sow_now.into_next', month: this_month, next: next_month)
  end

  # Every month as a chip, for a screen wide enough to show them all.
  def seed_month_chips
    [[t('seeds.library.labels.any_month'), { sow_month: nil }],
     [seed_sow_now_label, { sow_month: 'now' }],
     *seed_month_names.each_with_index.map { |name, index| [name, { sow_month: index + 1 }] }]
  end

  # The chips in their labelled groups. How far away only means something on
  # other people's seeds, and sharing only on a gardener's own: everyone's are
  # all shared. The months are chips on a wide screen, and a select on a narrow
  # one, so that group says it is `wide_only`.
  def seed_filter_groups(everyone:)
    [['labels.month_to_sow', seed_month_chips, true],
     ['filters.source', seed_source_chips],
     (['filters.distance', seed_distance_chips] if everyone && current_member&.latitude),
     (['filters.sharing', seed_sharing_chips] unless everyone),
     ['filters.heirloom', seed_heirloom_chips],
     ['filters.planted', seed_planted_chips]].compact.map do |label_key, chips, wide_only|
      { label:     t("seeds.library.#{label_key}"),
        wide_only: wide_only || false,
        chips:     chips.map { |label, params| { label:, params: } } }
    end
  end

  # The people a member follows, to suggest when looking for a gardener's seeds.
  def seed_friend_names
    current_member ? current_member.followed.order(:login_name).pluck(:login_name) : []
  end
end

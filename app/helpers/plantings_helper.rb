# frozen_string_literal: true

module PlantingsHelper
  include PlantingWeatherHelper
  include SeedsHelper

  # Pictures for the ways a planting was started and where it came from, from the icons the site already has.
  ORIGIN_KIND_ICONS = {
    'seed' => 'icons/seeds.svg', 'seedling' => 'icons/sprout.svg', 'cutting' => 'icons/plant_parts/stem.svg',
    'root division' => 'icons/plant_parts/root.svg', 'runner' => 'icons/plant_parts/other.svg', 'bulb' => 'icons/plant_parts/bulb.svg',
    'root/tuber' => 'icons/plant_parts/tuber.svg', 'bare root plant' => 'icons/plant_parts/whole plant.svg',
    'advanced plant' => 'crops/potted_plant.svg', 'graft' => 'icons/plant_parts/other.svg', 'layering' => 'icons/plant_parts/other.svg',
    'volunteer' => 'icons/grass.svg'
  }.freeze
  ORIGIN_SOURCE_ICONS = {
    'seed catalogue' => 'icons/post.svg', 'retail outlet' => 'icons/wheelbarrow.svg',
    'seed bank or similar institution' => 'icons/seeds.svg', 'traded from another person' => 'icons/trade.svg',
    'my own seed saving' => 'icons/gardener.svg', 'other/unknown' => 'icons/plant_parts/other.svg',
    'shop' => 'icons/wheelbarrow.svg', 'nursery' => 'crops/potted_plant.svg', 'market' => 'icons/harvest.svg',
    'gift' => 'icons/trade.svg', 'unknown' => 'icons/plant_parts/other.svg'
  }.freeze

  def days_from_now_to_first_harvest(planting)
    return unless planting.planted_at.present? && planting.first_harvest_predicted_at.present?

    (planting.first_harvest_predicted_at - Time.zone.today).to_i
  end

  # Returns a list of gardens the planting can be transplanted to
  # based on the planting's owner.
  def transplantable_gardens_by_owner(planting)
    @transplantable_gardens ||= {}
    cache_key = planting.id || planting.object_id
    @transplantable_gardens[cache_key] ||= begin
      garden_ids = planting.owner.gardens.select(:id).to_a + GardenCollaborator.where(member_id: planting.owner.id).select(:garden_id).to_a

      Garden.active.where.not(id: planting.garden_id).where(id: garden_ids)
    end
  end

  # What the PlantingActions island needs: the planting itself, the menu items
  # (the server still decides labels, links and permissions), and the icons the
  # dialogs show in their headers. Mirrors GardenCardSerializer#planting_actions
  # so the menu is the same on a card and on the planting's own page.
  def planting_actions_props(planting)
    {
      planting:         {
        id:         planting.id,
        url:        planting_path(planting),
        # The finish and harvest dialogs need these: neither may happen before
        # the planting was planted, and the server's today is the one that
        # counts, not the browser's.
        planted_at: planting.planted_at,
        today:      Time.zone.today,
        crop:       { name: planting.crop.name, icon_url: crop_icon_url(planting.crop) }
      },
      actions:          planting_menu_actions(planting),
      harvest_icon_url: image_path('icons/harvest.svg'),
      seed_icon_url:    image_path('icons/seeds.svg'),
      photo_icon_url:   image_path('icons/photo.svg'),
      finish_icon_url:  image_path('icons/finish.svg')
    }
  end

  # What the PlantingOrigin island needs: where the planting stands, and the packets, kinds and sources it offers.
  def planting_origin_props(planting)
    {
      url:              planting_origin_path(planting),
      crop:             planting.crop.name,
      crop_id:          planting.crop_id,
      kinds:            planting_origin_kinds,
      seeds:            planting_origin_seeds(planting),
      current_seed:     planting.parent_seed && planting_origin_seed(planting.parent_seed, planting.crop),
      seed_sources:     origin_options(Seed::SOURCE_VALUES, 'seed_sources'),
      seedling_sources: origin_options(PlantingSeedling::SOURCES, 'seedling_sources'),
      labels:           t('plantings.origin.dialog')
    }
  end

  # The translation key for a planted_from value: "root/tuber" is root_tuber.
  def planted_from_key(value)
    value.parameterize(separator: '_')
  end

  def planting_origin_kind_icon_url(kind)
    image_path(ORIGIN_KIND_ICONS.fetch(kind))
  end

  # Edit, add photo, the state changes, then delete last below a divider.
  def planting_menu_actions(planting)
    return [] unless can?(:edit, planting)

    actions = [{ key: 'edit', label: t('buttons.edit'), href: edit_planting_path(planting) }]
    if can?(:create, Photo)
      actions << { key: 'photo', label: t('buttons.add_photo'),
                   href: new_photo_path(id: planting.id, type: 'planting') }
    end
    actions.concat(active_planting_menu_actions(planting)) if planting.active
    actions << planting_delete_action(planting)
    actions.compact
  end

  def active_planting_menu_actions(planting)
    actions = []
    if can?(:create, Harvest)
      actions << { key: 'harvest', label: t('buttons.record_harvest'),
                   href: new_planting_harvest_path(planting_slug: planting.slug) }
    end
    unless planting.failed?
      actions << { key: 'seeds', label: t('buttons.save_seeds'),
                   href: new_planting_seed_path(planting_slug: planting.slug) }
    end
    actions << { key: 'finish', label: t('buttons.mark_as_finished'),
                 href: planting_path(slug: planting.slug, planting: { finished: 1 }), method: 'put' }
    if can?(:transplant, planting) && transplantable_gardens_by_owner(planting).any?
      actions << { key: 'transplant', label: 'Transplant', href: '#transplant-modal' }
    end
    actions
  end

  def planting_delete_action(planting)
    return unless can?(:destroy, planting)

    { key: 'delete', label: t('buttons.delete'), href: planting_path(planting),
      method: 'delete', confirm: t('are_you_sure'), divider: true }
  end

  private

  def crop_icon_url(crop)
    crop_path(crop, format: 'svg') if crop.svg_icon.present?
  end

  # Seed, seedling and cutting are asked about first, with the other ways below them.
  def planting_origin_kinds
    Planting::PLANTED_FROM_VALUES.map do |value|
      key = planted_from_key(value)
      { value: value, label: t("plantings.origin.kinds.#{key}"), main: %w(seed seedling cutting).include?(value),
        hint: t("plantings.origin.kind_hints.#{key}", default: ''), icon_url: planting_origin_kind_icon_url(value) }
    end
  end

  def origin_options(values, scope)
    values.map do |value|
      icon = ORIGIN_SOURCE_ICONS[value]
      { value: value, label: t("plantings.origin.#{scope}.#{value}"), icon_url: icon && image_path(icon) }
    end
  end

  # Their packets: those of exactly this crop first, then the rest, each most recent first. `related` ones are of this crop
  # or its variety or parent, and are the ones the dialog lists before anything is typed.
  def planting_origin_seeds(planting)
    seeds = planting.owner.seeds.includes(:crop, :photos).order(created_at: :desc).limit(200).to_a
    seeds.sort_by.with_index { |seed, index| [seed.crop_id == planting.crop_id ? 0 : 1, index] }
      .map { |seed| planting_origin_seed(seed, planting.crop) }
  end

  def planting_origin_seed(seed, crop)
    photo = seed.photos.first
    { id: seed.id, name: seed.crop.name, variety: seed.variety.presence, photo_url: (thumbnail_url(photo) if photo),
      icon_url: crop_icon_url(seed.crop), detail: planting_origin_seed_detail(seed),
      related: [seed.crop_id, seed.crop.parent_id].intersect?([crop.id, crop.parent_id].compact) }
  end

  def planting_origin_seed_detail(seed)
    source = t("plantings.origin.seed_sources.#{seed.source}") if seed.source.present? && seed.source != 'other/unknown'
    [seed.saved_at && t('plantings.origin.saved_in', year: seed.saved_at.year),
     (seed.heirloom if seed.heirloom != 'unknown'), source, seed_packet_sow_by(seed)].compact.join(' · ')
  end
end

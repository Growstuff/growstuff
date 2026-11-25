# frozen_string_literal: true

module ObservationsHelper
  ICONS = {
    'germination' => 'seedling', 'flowering' => 'spa', 'fruiting' => 'apple-whole',
    'wilting' => 'arrow-trend-down', 'disease_observed' => 'bug'
  }.freeze

  # The kinds of observation to choose from, with their wording. Observations with no kind are "other".
  def observation_kind_options
    @observation_kind_options ||= (Observation::KINDS + ['other']).map do |kind|
      { value: kind, label: observation_kind_label(kind), icon: observation_icon_name(kind) }
    end
  end

  # The icon on an observation's place on the timeline and in the dialog; "other" has a question mark.
  def observation_icon(kind)
    icon 'fas', observation_icon_name(kind)
  end

  # What the edit dialog starts from.
  def observation_edit_data(observation)
    { id: observation.id, kind: observation.kind, observed_on: observation.observed_at.to_date.iso8601,
      description: observation.description }
  end

  # What the harvest edit dialog starts from.
  def harvest_edit_data(harvest)
    { slug: harvest.slug, plant_part_id: harvest.plant_part_id, quantity: harvest.quantity&.to_f, unit: harvest.unit,
      weight_quantity: harvest.weight_quantity&.to_f, weight_unit: harvest.weight_unit,
      harvested_at: (harvest.harvested_at || harvest.created_at.to_date).iso8601, description: harvest.description }
  end

  def observation_icon_name(kind)
    ICONS.fetch(kind, 'circle-question')
  end

  def observation_kind_label(kind)
    t("observations.kinds.#{kind || 'other'}")
  end
end

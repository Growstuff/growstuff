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

  def observation_icon_name(kind)
    ICONS.fetch(kind, 'circle-question')
  end

  def observation_kind_label(kind)
    t("observations.kinds.#{kind || 'other'}")
  end

  # How many days into the planting it was noticed, if we know when it was planted.
  def observation_day(observation, planting)
    return if planting.planted_at.blank?

    days = (observation.observed_at.to_date - planting.planted_at).to_i
    days if days >= 0
  end
end

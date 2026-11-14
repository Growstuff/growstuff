# frozen_string_literal: true

module ObservationsHelper
  # The kinds of observation to choose from, with their wording.
  def observation_kind_options
    kinds = Observation::KINDS.map { |kind| { value: kind, label: observation_kind_label(kind) } }
    kinds << { value: 'other', label: observation_kind_label(nil) }
  end

  OBSERVATION_ICONS = {
    'germination' => 'seedling', 'flowering' => 'spa', 'fruiting' => 'apple-whole',
    'wilting' => 'arrow-trend-down', 'disease_observed' => 'bug'
  }.freeze

  # The icon on an observation's place on the timeline; "other" has a question mark.
  def observation_icon(kind)
    icon 'fas', OBSERVATION_ICONS.fetch(kind, 'circle-question')
  end

  # An observation with no kind is "other".
  def observation_kind_label(kind)
    t("observations.kinds.#{kind || 'other'}")
  end

  # The dialog for noting something about the planting; the link is where it goes without JavaScript.
  def observation_action(planting)
    { key: 'observation', label: t('buttons.add_observation'), href: planting_path(planting, anchor: 'observations') }
  end
end

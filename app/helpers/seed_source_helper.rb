# frozen_string_literal: true

# Where a packet of seed came from, as a ribbon on its hero photo. Every source has
# one but 'other/unknown', which is the model's own "don't know" and is left
# unsaid, as it is everywhere else on the page. The grower can change it from the
# ribbon itself.
module SeedSourceHelper
  # The ribbon's own name, for styling.
  SOURCE_RIBBONS = {
    'my own seed saving'               => 'saved',
    'retail outlet'                    => 'bought',
    'seed catalogue'                   => 'catalogue',
    'seed bank or similar institution' => 'bank',
    'traded from another person'       => 'traded'
  }.freeze

  # What the others say. Seed saved by the grower says who and when instead.
  SOURCE_WORDS = {
    'bought'    => 'Bought',
    'catalogue' => 'Catalogue',
    'bank'      => 'Seed bank',
    'traded'    => 'Traded'
  }.freeze

  # What the ribbon says: "Saved by shiny in 2026" for seed the grower saved
  # (leaving out the year if it is not known), otherwise where it was got.
  def seed_source_words(seed)
    kind = SOURCE_RIBBONS[seed.source]
    return SOURCE_WORDS[kind] unless kind == 'saved'

    year = "in #{seed.saved_at.year}" if seed.saved_at
    ["Saved by #{seed.owner}", year].compact.join(' ')
  end

  # The ribbon for a seed's source, or a plain badge of the same words for a hero
  # that has no photo to hang a ribbon on. Nothing for an unknown source.
  def seed_source_ribbon(seed, ribbon: true)
    return unless SOURCE_RIBBONS[seed.source]

    tag.span(seed_source_words(seed), class: source_classes(seed, ribbon), title: "Source: #{seed.source}")
  end

  # The ribbon, for the grower, as a button that opens the choices of where the
  # packet came from. An unknown source gets a faint "Where from?" to say there is
  # one to set. Anyone else gets the plain ribbon.
  def seed_source_control(seed, ribbon: true)
    return seed_source_ribbon(seed, ribbon:) unless can?(:update, seed)

    toggle = tag.button(safe_join([seed_source_words(seed) || 'Where from?', tag.span(' ▾', 'aria-hidden': 'true')]),
                        type: 'button', class: "#{source_classes(seed, ribbon)} seed-source-toggle",
                        title: 'Where did these seeds come from?', 'aria-expanded': 'false',
                        data: { 'bs-toggle': 'dropdown' })
    tag.div(class: 'seed-source-menu dropdown') { toggle + source_choices(seed) }
  end

  private

  def source_classes(seed, ribbon)
    return 'badge text-bg-secondary seed-source-badge' unless ribbon

    "seed-source-ribbon seed-source-ribbon--#{SOURCE_RIBBONS.fetch(seed.source, 'unset')}"
  end

  def source_choices(seed)
    choices = Seed::SOURCE_VALUES.map do |source|
      link_to source.capitalize, seed_path(seed, seed: { source: }),
              method: :put, class: ['dropdown-item', ('active' if source == seed.source)]
    end
    tag.div(safe_join(choices), class: 'dropdown-menu dropdown-menu-end')
  end
end

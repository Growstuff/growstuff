# frozen_string_literal: true

module StallsHelper
  # What the GiveAwayForm island needs: the nursery's seedlings to choose from, what is already chosen, and everything it
  # says, from the locale. `selected` maps a planting's id to how many of it were chosen, or nil for all.
  def give_away_props(seedlings:, selected:, status:, values:, recipients:, errors: [])
    {
      action: stall_plantings_path, csrf: form_authenticity_token, cancelUrl: member_stall_path(current_member),
      recipientsUrl: stall_recipients_path, today: Time.zone.today.iso8601, labels: I18n.t('stalls.plantings.form'),
      seedlings: seedlings.map { |planting| give_away_seedling(planting) }, selected:,
      offeredIds: current_member.stall&.seedlings_on_offer&.pluck(:planting_id).to_a,
      status: status.to_s, values:, errors:, suggestions: recipients.suggestions,
      picked: (recipients.person(values['recipient_member_id']) if values['recipient_member_id'].present?)
    }
  end

  private

  # A batch, as a row to choose: "Cucumber seedlings", "Marketmore · sown 3 Oct, 6 weeks ago".
  def give_away_seedling(planting)
    sown = give_away_sown(planting.planted_at) if planting.planted_at
    {
      id: planting.id, total: planting.quantity || 1,
      label: I18n.t('stalls.plantings.form.seedling_name', crop: planting.display_name),
      detail: [planting.parent_seed&.variety.presence, sown].compact.join(' · ')
    }
  end

  def give_away_sown(day)
    I18n.t('stalls.plantings.form.sown', date: l(day, format: '%-d %b'), ago: time_ago_in_words(day))
  end
end

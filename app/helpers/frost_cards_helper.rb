# frozen_string_literal: true

# The figures under the timeline of the frost section: see FrostSectionHelper.
module FrostCardsHelper
  # { label:, value:, note: } for each figure. A planting that has finished has no frost-free season.
  def frost_cards(frost)
    return [frost_last_card(frost), frost_next_card(frost), frost_free_card(frost)].compact unless frost_planting?(frost)

    cards = [frost_margin_card(frost), (frost_in_danger_card(frost) if frost.finished?), frost_last_card(frost), frost_next_card(frost)]
    cards << frost_free_card(frost) unless frost.finished?
    cards.compact
  end

  private

  def frost_margin_card(frost)
    return unless frost.margin_c

    note = t('frost.cards.margin.note', coldest: frost_degrees(frost.coldest_night_c), threshold: frost_degrees(FrostSeason::THRESHOLD_C))
    { label: t('frost.cards.margin.label'), value: t('frost.degrees', degrees: frost_degrees(frost.margin_c)), note: }
  end

  def frost_in_danger_card(frost)
    { label: t('frost.cards.in_danger.label'), value: frost_days(frost.days_in_danger),
      note: t('frost.cards.in_danger.note', latest: frost_date_text(frost.possible.last)) }
  end

  def frost_last_card(frost)
    note = if frost_planting?(frost) && frost.finished? && !frost.long_lived?
             frost_planted_note(frost)
           else
             t('frost.cards.last.note', latest: frost_date_text(frost.possible.last))
           end
    { label: t('frost.cards.last.label'), value: frost_date_text(frost.usual.last), note: }
  end

  def frost_planted_note(frost)
    count = frost.planted_days_before_usual_end
    t("frost.cards.last.planted_#{count.negative? ? 'after' : 'before'}", days: frost_days(count.abs))
  end

  def frost_next_card(frost)
    key = if frost_planting?(frost) && frost.finished? then 'note_finished'
          elsif frost_planting?(frost) && frost.end_ahead? then 'note_finishes'
          else 'note_now'
          end
    note = t("frost.cards.next.#{key}", earliest: frost_date_text(frost.next_season_earliest),
                                        days:     frost_days(frost.days_to_next_season))
    { label: t('frost.cards.next.label'), value: frost_date_text(frost.next_season_start), note: }
  end

  def frost_free_card(frost)
    return unless frost.frost_free_days

    { label: t('frost.cards.free.label'), value: frost_days(frost.frost_free_days), note: t('frost.cards.free.note') }
  end
end

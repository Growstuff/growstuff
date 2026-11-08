# frozen_string_literal: true

# The timeline of the frost section: the bands along it, today's marker and the months, from a PlantingFrost.
# See FrostSectionHelper for the rest of the section.
module FrostTimelineHelper
  # A band of the timeline, placed along it. The frost danger that is only possible has no label.
  def frost_band_tag(frost, band)
    label = frost_band_label(frost, band) unless band.kind == :possible
    style = "left: #{frost_percent(frost.position(band.from))}; width: #{frost_percent(frost.width(band))}"
    # The label can be too long for a short band, so every band says it again on hover, and on tap or focus: tabindex lets a
    # click or a tap focus it, and the tooltip goes when focus moves.
    tag.div(label && tag.span(label, class: 'frost-band-label'), class: "frost-band frost-band--#{band.kind}", style:, tabindex: 0,
                                                                   title: frost_band_tip(frost, band),
                                                                   data: { bs_toggle: 'tooltip', bs_trigger: 'hover focus' })
  end

  # The marker for today, and a line down through both rows, for a planting still growing.
  def frost_today_tags(frost)
    return unless frost.show_today?

    style = "left: #{frost_percent(frost.position(frost.today))}"
    pill = tag.span(t('frost.timeline.today', date: frost_date_text(frost.today)), class: 'frost-today', style:)
    safe_join([pill, tag.div(class: 'frost-today-line', style:)])
  end

  # The month starts along the axis, with the year where it starts a year or the axis. They shrink to initials on a phone.
  def frost_axis_tags(frost)
    ticks = frost.axis.select { |date| date.day == 1 }.map do |date|
      name = l(date, format: '%b')
      year = tag.span(date.year, class: 'frost-year') if date.month == 1 || date == frost.axis.first
      parts = [tag.span(name, class: 'frost-month-long'), tag.span(name.first, class: 'frost-month-short'), year]
      tag.div(safe_join(parts), class: 'frost-tick', style: "left: #{frost_percent(frost.position(date))}")
    end
    safe_join(ticks)
  end

  def frost_percent(fraction)
    "#{(fraction * 100).round(3)}%"
  end

  # The line under the planting's row: how its start sits against the usual last frost.
  def frost_annotation(frost)
    t("frost.timeline.annotation#{frost_out(frost)}_#{frost_direction(frost)}", days: frost_planted_days(frost))
  end

  # The timeline in words, for a screen reader.
  def frost_timeline_description(frost)
    planting = frost_planting?(frost)
    dates = frost_season_dates(frost)
    dates.merge!(planted: frost_date_text(frost.planted_on), ends: frost_date_text(frost.ends_on)) if planting
    key = if !planting then 'description_place'
          elsif frost.end_unknown? then 'description_undated'
          else 'description'
          end
    t("frost.timeline.#{key}", crop: frost_crop(frost), from: frost_month_year(frost.axis.first),
                               to: frost_month_year(frost.axis.last), **dates)
  end

  # The label on a band of the timeline.
  def frost_band_label(frost, band)
    case band.kind
    when :usual then frost_usual_label(band)
    when :so_far then t("frost.timeline.planted#{frost_out(frost)}", date: frost_date_text(frost.planted_on))
    when :planted then t('frost.timeline.planted', date: frost_date_text(frost.planted_on))
    when :frost_safe then t('frost.timeline.frost_safe', place: frost.safe_place)
    when :still_to_come then t('frost.timeline.finish_expected', date: frost_date_text(frost.ends_on))
    when :finished then t('frost.timeline.finished', date: frost_date_text(frost.ends_on))
    end
  end

  # What a band says when hovered or clicked: what it is and the dates it covers.
  def frost_band_tip(frost, band)
    range = t('frost.timeline.usual', from: frost_date_text(band.from), to: frost_date_text(band.last || band.to))
    case band.kind
    when :usual, :possible then t("frost.timeline.tips.#{band.kind}", range:)
    when :frost_safe then t('frost.timeline.tips.frost_safe', place: frost.safe_place, range:)
    when :planted then frost_band_label(frost, band)
    else t('frost.timeline.tips.planting', range:, label: frost_band_label(frost, band))
    end
  end

  private

  def frost_month_year(date)
    l(date, format: '%B %Y')
  end

  def frost_usual_label(band)
    from = frost_date_text(band.from)
    return t('frost.timeline.usual_open', from:) if band.open?

    t('frost.timeline.usual', from:, to: frost_date_text(band.to))
  end
end

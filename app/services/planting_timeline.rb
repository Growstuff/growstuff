# frozen_string_literal: true

# The events of a planting's life, in order, placed along a line from the day it was planted to its last event:
# sown or planted, each time it was moved to another garden, first and last harvest, and finished. An event is
# expected when it hasn't happened yet or when we are predicting it, as the harvests and the finish usually are.
# Predicted events stay in the order of a life: first harvest, last harvest, finish.
class PlantingTimeline
  Event = Data.define(:kind, :date, :expected, :garden)

  # An event as it is drawn: its label and icon, how far along the line it is as a percentage, which side of the
  # line its label goes, and whether it is near enough an end of the line for the label to lean inwards.
  Marker = Data.define(:kind, :label, :date, :expected, :percent, :side, :edge, :icon) do
    # What sets how it is drawn, each a modifier of the event's class in the stylesheet.
    def modifiers
      [side, edge, (:expected if expected), (:failed if kind == :failed)].compact
    end
  end

  # The icon, in app/assets/images/icons, the site uses for each kind of event: planting for planted or sown,
  # growing for a move, harvest for both harvests, and finish for finished or failed.
  ICONS = {
    sown: 'planting', planted: 'planting', transplanted: 'growing', first_harvest: 'harvest', last_harvest: 'harvest',
    finished: 'finish', failed: 'finish'
  }.freeze

  # A label this near an end of the line, as a percentage of it, leans inwards to stay on the page.
  EDGE_PERCENT = 12

  def initialize(planting, today: Time.zone.today)
    @planting = planting
    @today = today
  end

  # Worth drawing: planted, and with another event, on a later day, to draw it to.
  def show?
    @planting.planted_at.present? && events.size > 1 && finish > start
  end

  def events
    @events ||= [planting_event, *transplant_events, first_harvest_event, last_harvest_event, finish_event]
      .compact.each_with_index.sort_by { |event, index| [event.date, index] }.map(&:first)
  end

  # The events placed and labelled for drawing, their labels on alternate sides of the line so neighbours don't overlap.
  def markers
    events.each_with_index.map do |event, index|
      percent = position(event.date)
      Marker.new(kind: event.kind, label: I18n.t("plantings.timeline.#{event.kind}", garden: event.garden&.name),
                 date: event.date, expected: event.expected, percent:, side: index.even? ? :above : :below,
                 edge: edge(percent), icon: ICONS.fetch(event.kind))
    end
  end

  def start
    @planting.planted_at
  end

  # The last day on the line: the last event, or today if that is later and the planting is still going.
  def finish
    last = events.map(&:date).max
    @planting.finished? || last.nil? ? last : [last, @today].max
  end

  # How many days the line covers.
  def days
    (finish - start).to_i
  end

  # How far along the line a date is, as a percentage.
  def position(date)
    return 0.0 unless days.positive?

    (((date - start).to_f / days) * 100).clamp(0, 100).round(2)
  end

  # How far along the line today is, or nil for a planting that hasn't started or has finished.
  def today_position
    position(@today) if start <= @today && !@planting.finished?
  end

  # How far along the line the fill goes: all of it for a planting that has finished, otherwise as far as today.
  def fill_position
    @planting.finished? ? 100 : (today_position || 0)
  end

  # For the React cards: what to draw, with the labels and icons the server has chosen. Dates are as "2026-09-12".
  def as_json(*)
    { state: @planting.progress_state, fill: fill_position, today: today_position, expected_label: I18n.t('plantings.timeline.expected'),
      today_label: I18n.t('plantings.timeline.today'), events: markers.map { |marker| marker_json(marker) } }
  end

  private

  def edge(percent)
    if percent < EDGE_PERCENT then :start
    elsif percent > 100 - EDGE_PERCENT then :end
    else :middle
    end
  end

  def marker_json(marker)
    marker.to_h.except(:icon, :side, :edge).merge(
      date: marker.date.iso8601, modifiers: marker.modifiers,
      icon_url: ActionController::Base.helpers.image_path("icons/#{marker.icon}.svg")
    )
  end

  # An event on a day. One we know of is expected only if its day is still to come; a prediction always is.
  def event(kind, date, expected: date.to_date > @today, garden: nil)
    Event.new(kind:, date: date.to_date, expected:, garden:)
  end

  # Sown for a planting that began as seed, planted for anything else.
  def planting_event
    return if @planting.planted_at.blank?

    seed = @planting.planted_from == 'seed' || (@planting.planted_from.blank? && @planting.parent_seed.present?)
    event(seed ? :sown : :planted, @planting.planted_at)
  end

  # Each move to another garden: the day it left one, and where it went.
  def transplant_events
    @planting.histories.map { |history| event(:transplanted, history.ended_on, garden: history.moved_to) }
  end

  def first_harvest_event
    if (actual = @planting.first_harvest_date)
      event(:first_harvest, actual)
    elsif (predicted = @planting.first_harvest_predicted_at)
      event(:first_harvest, predicted, expected: true)
    end
  end

  # The last harvest we know of once the planting is done, else when it is expected: never before the first, and
  # not drawn on top of it.
  def last_harvest_event
    first = first_harvest_event&.date
    last = if @planting.finished? && (actual = @planting.last_harvest_date)
             event(:last_harvest, actual, expected: false)
           elsif (predicted = @planting.last_harvest_predicted_at)
             event(:last_harvest, [predicted.to_date, first].compact.max, expected: true)
           end
    last unless last&.date == first
  end

  # The crop's median lifespan and its median days to harvest come from different plantings, so a finish can be predicted
  # before the harvests. A planting can't finish before it is harvested, so the predicted finish is never before them.
  def finish_event
    if (actual = @planting.finished_at)
      event(@planting.failed? ? :failed : :finished, actual)
    elsif (predicted = @planting.finish_predicted_at)
      event(:finished, [predicted.to_date, first_harvest_event&.date, last_harvest_event&.date].compact.max, expected: true)
    end
  end
end

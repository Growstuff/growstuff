# frozen_string_literal: true

# The events of a planting's life, in order, placed along a line from the day it was planted to its last event:
# sown or planted, each time it was moved to another garden, first and last harvest, and finished. An event is
# expected when it hasn't happened yet or when we are predicting it, as the harvests and the finish usually are.
# Predicted events stay in the order of a life: first harvest, last harvest, finish.
class PlantingTimeline
  Event = Data.define(:kind, :date, :expected, :garden)

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

  def start
    @planting.planted_at
  end

  # The last day on the line: the last event, or today if that is later and the planting is still going.
  def finish
    last = events.map(&:date).max
    @planting.finished? || last.nil? ? last : [last, @today].max
  end

  # How far along the line a date is, as a percentage.
  def position(date)
    return 0.0 if finish <= start

    (((date - start).to_f / (finish - start)) * 100).clamp(0, 100).round(2)
  end

  # How far along the line today is, or nil for a planting that hasn't started or has finished.
  def today_position
    position(@today) if @planting.planted_at <= @today && !@planting.finished?
  end

  private

  # Sown for a planting that began as seed, planted for anything else.
  def planting_event
    return if @planting.planted_at.blank?

    seed = @planting.planted_from == 'seed' || (@planting.planted_from.blank? && @planting.parent_seed.present?)
    Event.new(kind: seed ? :sown : :planted, date: @planting.planted_at, expected: @planting.planted_at > @today, garden: nil)
  end

  # Each move to another garden: the day it left one, and where it went.
  def transplant_events
    @planting.histories.map do |history|
      Event.new(kind: :transplanted, date: history.ended_on, expected: history.ended_on > @today, garden: history.moved_to)
    end
  end

  def first_harvest_event
    actual = @planting.first_harvest_date
    return Event.new(kind: :first_harvest, date: actual.to_date, expected: actual.to_date > @today, garden: nil) if actual

    predicted = @planting.first_harvest_predicted_at
    Event.new(kind: :first_harvest, date: predicted.to_date, expected: true, garden: nil) if predicted
  end

  # The last harvest we know of once the planting is done, else when it is expected. Not drawn on top of the first.
  def last_harvest_event
    actual = @planting.last_harvest_date if @planting.finished?
    event = if actual
              Event.new(kind: :last_harvest, date: actual.to_date, expected: false, garden: nil)
            elsif (predicted = @planting.last_harvest_predicted_at)
              Event.new(kind: :last_harvest, date: [predicted.to_date, first_harvest_event&.date].compact.max, expected: true, garden: nil)
            end
    event unless event.nil? || event.date == first_harvest_event&.date
  end

  # The crop's median lifespan and its median days to harvest come from different plantings, so a finish can be predicted
  # before the harvests. A planting can't finish before it is harvested, so the predicted finish is never before them.
  def harvest_dates
    [first_harvest_event, last_harvest_event].compact.map(&:date)
  end

  def finish_event
    if @planting.finished_at
      Event.new(kind: @planting.failed? ? :failed : :finished, date: @planting.finished_at, expected: @planting.finished_at > @today,
                garden: nil)
    elsif @planting.finish_predicted_at
      Event.new(kind: :finished, date: [@planting.finish_predicted_at.to_date, *harvest_dates].max, expected: true, garden: nil)
    end
  end
end

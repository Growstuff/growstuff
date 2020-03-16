# frozen_string_literal: true

module EventHelper
  def in_weeks(days)
    (days / 7.0).round
  end

  def event_description(event)
    render "#{event.event_type.pluralize}/description", event_model: resolve_model(event)
  end

  def resolve_model(event)
    event.event_type.classify.constantize.find(event.id)
  end
end

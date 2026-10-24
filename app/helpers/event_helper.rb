# frozen_string_literal: true

module EventHelper
  def in_weeks(days)
    (days / 7.0).round
  end

  # A "job_finished" event is described by jobs/_finished_description.
  def event_description(event)
    model = resolve_model(event)
    partial = event.event_type.end_with?('_finished') ? 'finished_description' : 'description'
    render "#{model.model_name.collection}/#{partial}", event_model: model
  rescue ActionView::MissingTemplate
    "#{event.event_type.humanize.downcase}d"
  end

  def resolve_model(event)
    event.event_type.delete_suffix('_finished').classify.constantize.find(event.id)
  end
end

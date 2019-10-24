module EventHelper
  def event_description(event)
    render "#{event.event_type.pluralize}/description", event_model: resolve_model(event)
  end

  def resolve_model(event)
    event.event_type.classify.constantize.find(event.id)
  end
end

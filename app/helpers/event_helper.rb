module EventHelper
  def event_description(event)
    event_model = resolve_model(event)
    if event.event_type == 'planting'
      "planted #{link_to event_model.crop, event_model}"
    elsif event.event_type == 'seed'
      "saved #{link_to event_model.crop, event_model} seeds"
    elsif event.event_type == 'harvest'
      "harvested #{link_to event_model, event_model}"
    elsif event.event_type == 'comment'
      "#{link_to 'commented', event_model} on #{link_to event_model.post, event_model.post}"
    elsif event.event_type == 'post'
      "wrote a post about #{link_to event_model, event_model}"
    elsif event.event_type == 'photo'
      "took a photo #{link_to event_model.title, event_model}"
    end.html_safe
  end

  def resolve_model(event)
    event.event_type.classify.constantize.find(event.id)
  end
end

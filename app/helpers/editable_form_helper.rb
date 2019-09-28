module EditableFormHelper
  def editable(field_type, model, field, collection: [])
    render 'shared/editable/form', field_type: field_type,
      model: model, field: field, collection: collection
  end
  def editable_date(model, field, display_field:)
    render 'shared/editable/date', model: model, field: field, display_field: display_field
  end
end

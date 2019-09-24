module EditableFormHelper
  def editable(field_type, model, field, collection: [])
    render 'shared/editable/form', field_type: field_type,
      model: model, field: field, collection: collection
  end
end

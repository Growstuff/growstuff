# frozen_string_literal: true

module EditableFormHelper
  def editable(field_type, model, field, display_field:, collection: [])
    render 'shared/editable/form', field_type: field_type,
                                   model: model, field: field, display_field: display_field, collection: collection
  end
end

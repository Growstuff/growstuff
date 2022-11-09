# frozen_string_literal: true

module EditableFormHelper
  def editable(field_type, model, field, display_field:, collection: [])
    render 'shared/editable/form', field_type:,
                                   model:, field:, display_field:, collection:
  end
end

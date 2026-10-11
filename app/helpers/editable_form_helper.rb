# frozen_string_literal: true

module EditableFormHelper
  # The inline pencil beside a fact, and the little form it opens.
  #
  # `values` is whatever the field type needs to offer: the collection a
  # :select chooses from, or the range a :number_field is bounded by. The
  # other field types ignore it.
  def editable(field_type, model, field, display_field:, values: nil)
    render 'shared/editable/form', field_type:,
                                   model:, field:, display_field:, values:
  end
end

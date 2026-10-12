# frozen_string_literal: true

module EditableFormHelper
  # The inline pencil beside a fact, and the little form it opens.
  #
  # `values` is whatever the field type needs to offer: the collection a
  # :select chooses from, or the range a :number_field is bounded by. The
  # other field types ignore it. `field` may be a pair of attributes for
  # :number_range, which edits a min and a max together.
  def editable(field_type, model, field, display_field:, values: nil)
    render 'shared/editable/form', field_type:,
                                   model:, field:, display_field:, values:
  end

  # The id the form is given, so a trigger rendered somewhere else on the page
  # — the "edit" on a section's heading bar — can point at the same form.
  def editable_form_id(model, field)
    "form--#{model.id}-#{Array(field).first}"
  end
end

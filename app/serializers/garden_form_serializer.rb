# frozen_string_literal: true

# What the React edit-garden dialog needs to fill in its form: the garden's
# current values and the choices for its selects. Served by GET /gardens/:slug/edit.json.
class GardenFormSerializer
  def initialize(garden, member:)
    @garden = garden
    @member = member
  end

  def as_json(*)
    {
      garden:              values,
      area_units:          Garden::AREA_UNITS_VALUES.map { |label, value| { label: label, value: value } },
      garden_types:        GardenType.order(:name).map { |type| { id: type.id, name: type.name } },
      location_help:       I18n.t('gardens.form.location_helper'),
      member_has_location: @member.location.present?,
      settings_url:        Rails.application.routes.url_helpers.edit_member_registration_path
    }
  end

  private

  # As the edit page does: a garden with no location of its own shows the member's.
  def values
    {
      id: @garden.id, url: Rails.application.routes.url_helpers.garden_path(@garden),
      name: @garden.name, description: @garden.description,
      location: @garden.location.presence || @member.location,
      area: @garden.area, area_unit: @garden.area_unit.presence || Garden::AREA_UNITS_VALUES.values.first,
      garden_type_id: @garden.garden_type_id, active: @garden.active
    }
  end
end

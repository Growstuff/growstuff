# frozen_string_literal: true

# What the React save-seeds dialog needs to fill in its form: the crop and
# planting the seeds are from, today's date (they are being saved now), the
# choices for who they can be traded to, and where the member says they are, as
# trading is by location. Served by GET /plantings/:slug/seeds/new.json.
class SeedFormSerializer
  def initialize(planting, member:)
    @planting = planting
    @member = member
  end

  def as_json(*)
    {
      crop:               { id: @planting.crop_id, name: @planting.crop.name },
      parent_planting_id: @planting.id,
      saved_at:           Time.zone.today,
      tradable_to_values: Seed::TRADABLE_TO_VALUES,
      location:           @member.location.presence,
      settings_url:       Rails.application.routes.url_helpers.edit_member_registration_path
    }
  end
end

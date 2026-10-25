# frozen_string_literal: true

# What the React save-seeds dialog needs to fill in its form: the crop and
# planting the seeds are from, today's date (they are being saved now), the
# choices for who they can be traded to, and where the member says they are, as
# trading is by location. Served by GET /plantings/:slug/seeds/new.json, and
# by GET /seeds/new.json?crop_id= for seeds with no planting.
class SeedFormSerializer
  # Seeds saved without a planting (bought ones, say) are of a crop alone.
  def initialize(planting, member:, crop: nil)
    @planting = planting
    @crop = planting&.crop || crop
    @member = member
  end

  def as_json(*)
    {
      crop:               { id: @crop.id, name: @crop.name },
      parent_planting_id: @planting&.id,
      saved_at:           Time.zone.today,
      tradable_to_values: Seed::TRADABLE_TO_VALUES,
      location:           @member.location.presence,
      settings_url:       Rails.application.routes.url_helpers.edit_member_registration_path
    }
  end
end

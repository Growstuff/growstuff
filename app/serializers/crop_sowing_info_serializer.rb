# frozen_string_literal: true

# What the sow seeds dialog shows about a crop once it is chosen, so someone can
# tell they have the right one: a photo, what it is, how it grows, and what the
# member has done with it before. Served by GET /crops/:slug/sowing_info.json.
class CropSowingInfoSerializer
  include ActionView::Helpers::TextHelper

  def initialize(crop, member:)
    @crop = crop
    @member = member
  end

  include ApplicationHelper

  def as_json(*)
    {
      name:            @crop.name,
      url:             Rails.application.routes.url_helpers.crop_path(@crop),
      photo_url:       @crop.thumbnail_url,
      scientific_name: @crop.default_scientific_name&.name,
      description:     truncate(@crop.description.to_s, length: 300, separator: ' '),
      parent_name:     @crop.parent&.name,
      perennial:       @crop.perennial?,
      sun:             @crop.sun_requirements.presence,
      sowing_method:   @crop.sowing_method.presence,
      row_spacing_cm:  @crop.row_spacing,
      spread_cm:       @crop.spread,
      height_cm:       @crop.height,
      row_spacing_formatted: display_distance_cm(@crop.row_spacing, member: @member),
      spread_formatted:      display_distance_cm(@crop.spread, member: @member),
      height_formatted:      display_distance_cm(@crop.height, member: @member),
      days_to_harvest: @crop.median_days_to_first_harvest,
      grown_by:        @crop.plantings_count,
      usually_from:    @crop.planted_from.max_by { |_, count| count }&.first,
      your_plantings:  @member.plantings.where(crop: @crop).count,
      your_seeds:      @member.seeds.active.where(crop: @crop).count
    }
  end
end

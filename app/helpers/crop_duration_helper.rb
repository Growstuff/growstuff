# frozen_string_literal: true

# What crops#show says about how long a crop takes to a first harvest if sown now, and why a gardener's location would make
# that more accurate.
module CropDurationHelper
  # { days: the days as text, source: the key of what the figure is from, hint: the key of what to tell the gardener }, either
  # nil. The crop's growing degree days depend on where it is grown, so a hint is given when we can't use them for the member.
  def crop_duration_facts(crop, member)
    climate = member && SeasonalClimate.for(member)
    taking = CropDuration.for(crop, climate).from(Time.zone.today.month)
    hint = crop_duration_hint(crop, member, climate)
    return unless taking || hint

    { days: taking && crop_duration_days(taking), source: taking&.source, hint: }
  end

  # The days a crop takes as text: "90 days", or "90 to 120 days".
  def crop_duration_days(taking)
    low = taking.quick.round
    high = taking.slow.round
    high == low ? t('suggestions.climate.duration', count: low) : t('suggestions.climate.duration_range', low:, high:)
  end

  private

  def crop_duration_hint(crop, member, climate)
    return unless crop.growing_degree_days_figure && climate.nil?

    if member.nil? then :sign_in
    elsif !member.located? then :set_location
    else :no_climate
    end
  end
end

# frozen_string_literal: true

# The headline and sentences in the banner at the top of the rainfall and temperature sections of a place's page, from a
# PlaceClimate. The working out is in PlaceClimate and the words are in the locale files.
module ClimateVerdictHelper
  # The banner's headline and sentence for the rain, or nil with nothing to compare.
  def climate_rain_verdict(climate)
    comparison = climate.rain_comparison
    return unless comparison

    values = { rain: climate_figure(:rain, climate.rain_this_year), usual: climate_figure(:rain, climate.usual_rain_to_date),
               percent: (climate.rain_share * 100).round }
    { title: t("climate.rain.verdicts.#{comparison}"), body: t('climate.rain.body', **values) }
  end

  # The banner's headline and sentence for the air temperature, or nil with nothing to compare.
  def climate_air_verdict(climate)
    comparison = climate.air_comparison
    return unless comparison

    body = climate_air_sentence('body', comparison, climate.air_difference, air: climate.air_this_year, usual: climate.air_usual_to_date)
    { title: t("climate.air.verdicts.#{comparison}"), body:, recent: climate_air_recent(climate) }
  end

  private

  # How the air compares with usual, in the locale's sentence for a prefix such as 'body' or 'recent': close, above or below.
  def climate_air_sentence(prefix, comparison, difference, **values)
    direction = difference.negative? ? 'below' : 'above'
    t("climate.air.#{prefix}_#{comparison == :close ? 'close' : direction}", difference: difference.abs, **values)
  end

  # The sentence about the latest 30 days' air temperature, or nil with nothing to compare.
  def climate_air_recent(climate)
    comparison = climate.air_recent_comparison
    return unless comparison

    from, to = climate.recent_dates.minmax.map { |date| l(date, format: '%-d %B') }
    climate_air_sentence('recent', comparison, climate.air_recent_difference, air: climate.air_recent, usual: climate.air_recent_usual,
                                                                              from:, to:)
  end
end

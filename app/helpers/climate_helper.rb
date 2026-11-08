# frozen_string_literal: true

# What the rainfall and temperature sections of a place's page say and draw, from a PlaceClimate. The working out is in
# PlaceClimate and the words are in the locale files; this puts the two together.
module ClimateHelper
  # How far apart the lines on each chart are, in the measure's unit.
  CHART_STEPS = { rain: 100, air: 10, soil: 10 }.freeze
  UNITS = { rain: 'mm', air: 'celsius', soil: 'celsius' }.freeze
  # Outline icons, 24 by 24, for the banner of each section.
  ICONS = { rain: 'M12 3C8 8.5 6 11.5 6 15a6 6 0 0012 0c0-3.5-2-6.5-6-12z',
            air:  'M14 14.8V5a2 2 0 00-4 0v9.8a4 4 0 104 0z' }.freeze

  def climate_icon(measure)
    tag.svg(tag.path(d: ICONS.fetch(measure)), width: 24, height: 24, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor',
                                               'stroke-width': 2.5, 'stroke-linecap': 'round', 'stroke-linejoin': 'round',
                                               'aria-hidden': true)
  end

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

    difference = climate.air_difference
    key = if comparison == :close then 'body_close'
          else difference.negative? ? 'body_below' : 'body_above'
          end
    values = { air: climate.air_this_year, usual: climate.air_usual_to_date, difference: difference.abs }
    { title: t("climate.air.verdicts.#{comparison}"), body: t("climate.air.#{key}", **values) }
  end

  # The figures under the rain chart: { label:, value:, note: }.
  def climate_rain_cards(climate)
    [
      { label: t('climate.rain.cards.year'), value: climate_figure(:rain, climate.usual_rain_for_year),
        note: t('climate.years_average', count: climate.years_held) },
      climate_record_month_card(climate, 'wettest', :most), climate_record_month_card(climate, 'driest', :least)
    ].compact
  end

  # The figures under the temperature charts: the warmest and coldest months and the soil this month.
  def climate_air_cards(climate)
    cards = [climate_month_card(:air, 'warmest', climate.extreme_month(:air, :most)),
             climate_month_card(:air, 'coldest', climate.extreme_month(:air, :least))]
    soil = climate.this_year(:soil)[climate.today.month] || climate.this_year(:soil).values.last
    return cards unless soil

    cards << { label: t('climate.air.cards.soil'), value: climate_figure(:soil, soil), note: t('climate.air.cards.soil_note') }
  end

  # The hottest day, coldest night and so on, with where this year stands: { label:, value:, note: }.
  def climate_record_cards(climate)
    PlaceClimate::RECORDS.keys.filter_map do |name|
      record = climate.record(name)
      next unless record

      measure = climate_record_measure(name)
      this_year = climate.record_this_year(name)
      this_year_note = t('climate.records.this_year', value: climate_figure(measure, this_year.value)) if this_year
      { label: t("climate.records.#{name}"), value: climate_figure(measure, record.value),
        note: [l(record.on, format: '%-d %b %Y'), this_year_note].compact.join('. ') }
    end
  end

  # A figure as words: "1,070 mm" or "13.4 °C".
  def climate_figure(measure, value)
    if UNITS.fetch(measure) == 'mm'
      t('climate.units.mm', value: number_with_delimiter(value.round))
    else
      t('climate.units.celsius', value: number_with_precision(value, precision: 1))
    end
  end

  # Columns for each month, the usual figure behind this year's, on lines every few units, as a picture and in words.
  def climate_chart(climate, measure)
    usual = climate.usual(measure)
    year = climate.this_year(measure)
    scale = climate_scale(measure, usual.values + year.values)
    columns = (1..12).map { |month| climate_column(month, measure, [usual[month], year[month]], scale) }
    plot = tag.div(safe_join([*climate_gridlines(measure, scale), tag.div(safe_join(columns), class: 'climate-columns')]),
                   class: 'climate-plot')
    description = climate_chart_description(measure, usual, year)
    tag.div(safe_join([plot, climate_month_names]), class: 'climate-chart', role: 'img', 'aria-label': description)
  end

  # The months in a table: the usual and this year, for each measure given, as columns.
  def climate_table_rows(climate, measures)
    (1..12).map do |month|
      cells = measures.flat_map do |measure|
        [climate.usual(measure)[month], climate.this_year(measure)[month]].map { |value| climate_cell(measure, value) }
      end
      [climate_month_name(month, '%b'), *cells]
    end
  end

  private

  def climate_month_card(measure, key, extreme)
    month, value = extreme
    { label: t("climate.#{measure == :rain ? 'rain' : 'air'}.cards.#{key}"), value: climate_month_name(month, '%B'),
      note: t('climate.on_average', value: climate_figure(measure, value)) }
  end

  # The wettest or driest month on record: the month and year, and how much fell.
  def climate_record_month_card(climate, key, direction)
    record = climate.record_month(:rain, direction)
    return unless record

    { label: t("climate.rain.cards.#{key}"), value: climate_figure(:rain, record.value),
      note: t('climate.month_year', month: climate_month_name(record.month, '%B'), year: record.year) }
  end

  # The name of a month, in the format: "%b" for Jan, "%B" for January.
  def climate_month_name(month, format)
    l(Date.new(2000, month, 1), format:)
  end

  def climate_record_measure(name)
    name.to_s.end_with?('soil') ? :soil : :air
  end

  def climate_cell(measure, value)
    value ? climate_figure(measure, value) : t('climate.table.none')
  end

  # The lowest and highest line, and how far apart they are, for the figures: the chart runs from zero unless some are below.
  def climate_scale(measure, values)
    step = CHART_STEPS.fetch(measure)
    low = [(values.min.to_f / step).floor * step, 0].min
    high = [(values.max.to_f / step).ceil * step, step].max
    { low:, high:, step:, range: (high - low).to_f }
  end

  # How far up the chart a figure is, as a percentage.
  def climate_percent(value, scale)
    (value - scale[:low]) / scale[:range] * 100
  end

  def climate_gridlines(measure, scale)
    (scale[:low]..scale[:high]).step(scale[:step]).reject { |line| line == scale[:low] && line.zero? }.flat_map do |line|
      style = "bottom: #{climate_percent(line, scale).round(2)}%"
      [tag.div(class: 'climate-gridline', style:), tag.div(climate_figure(measure, line), class: 'climate-gridlabel', style:)]
    end
  end

  def climate_column(month, measure, figures, scale)
    bars = %w(usual year).zip(figures).filter_map do |kind, value|
      next unless value

      title = t('climate.chart.bar', month: climate_month_name(month, '%B'), kind: t("climate.chart.legend.#{kind}"),
                                     value: climate_figure(measure, value))
      climate_bar(kind, value, scale, title)
    end
    tag.div(safe_join(bars), class: 'climate-column')
  end

  # A bar from the zero line to the figure, up for a figure above it and down for one below.
  def climate_bar(kind, value, scale, title)
    zero = climate_percent(0, scale)
    top = climate_percent(value, scale)
    style = "bottom: #{[zero, top].min.round(2)}%; height: #{(top - zero).abs.round(2)}%"
    tag.div(class: "climate-bar climate-bar--#{kind}", style:, title:)
  end

  def climate_month_names
    names = (1..12).map do |month|
      name = climate_month_name(month, '%b')
      spans = [tag.span(name, class: 'climate-month-long'), tag.span(name.first, class: 'climate-month-short')]
      tag.div(safe_join(spans), class: 'climate-month')
    end
    tag.div(safe_join(names), class: 'climate-months')
  end

  def climate_chart_description(measure, usual, year)
    list = lambda do |figures|
      figures.map { |month, value| "#{climate_month_name(month, '%b')} #{climate_figure(measure, value)}" }.join(', ')
    end
    t('climate.chart.description', measure: t("climate.chart.measures.#{measure}"), usual: list.call(usual), year: list.call(year))
  end
end

# frozen_string_literal: true

# What EcoCrop says about the conditions a crop likes, as fact cards on the crop page.
module EcocropFactsHelper
  # A condition with a range the crop grows best in and one it survives in is one card with both, under an icon.
  # Each row is a label key and the fields of its range.
  ECOCROP_CONDITIONS = [
    { icon: 'thermometer-half', unit: :celsius,
      rows: { optimal_temperature: %i(topmn topmx), absolute_temperature: %i(tmin tmax) } },
    { icon: 'cloud-rain', unit: :rainfall,
      rows: { optimal_rainfall: %i(ropmn ropmx), absolute_rainfall: %i(rmin rmax) } },
    { icon: 'flask', unit: nil,
      rows: { optimal_ph: %i(phopmn phopmx), absolute_ph: %i(phmin phmax) } }
  ].freeze

  # Facts as { icon:, title:, rows: [{ label:, value: }] }, where title and label are blank when there is nothing to
  # tell the card from its icon. Leaves out what EcoCrop has nothing on, and shows a missing end of a range as "?".
  def ecocrop_facts(data)
    return [] unless data

    cards = ECOCROP_CONDITIONS.filter_map do |condition|
      rows = condition[:rows].filter_map do |key, fields|
        value = ecocrop_range(data, fields, condition[:unit])
        { label: I18n.t("crops.ecocrop_facts.#{key}"), value: } if value
      end
      { icon: condition[:icon], rows: } if rows.any?
    end
    cards.push(*[cycle_fact(data), altitude_fact(data), light_fact(data)].compact)
  end

  private

  # "18–32 °C"; nil when neither end is known.
  def ecocrop_range(data, fields, unit)
    ends = fields.map { |field| data[field] }
    return if ends.all?(&:blank?)

    range = ends.map { |value| value.nil? ? '?' : number_with_precision(value, precision: 2, strip_insignificant_zeros: true) }.join('–')
    [range, (I18n.t("crops.ecocrop_facts.units.#{unit}") if unit)].compact.join(' ')
  end

  def single_fact(key, icon, value)
    { icon:, title: I18n.t("crops.ecocrop_facts.#{key}"), rows: [{ value: }] }
  end

  def cycle_fact(data)
    value = ecocrop_range(data, %i(gmin gmax), :days)
    single_fact(:crop_cycle, 'calendar-alt', value) if value
  end

  def altitude_fact(data)
    single_fact(:max_altitude, 'mountain', "#{data.altmx} #{I18n.t('crops.ecocrop_facts.units.metres')}") if data.altmx.present?
  end

  def light_fact(data)
    levels = [data.liopmn, data.liopmx].compact_blank.uniq
    single_fact(:optimal_light, 'sun', levels.join(" #{I18n.t('crops.ecocrop_facts.to')} ")) if levels.any?
  end
end

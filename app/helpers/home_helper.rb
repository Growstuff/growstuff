# frozen_string_literal: true

module HomeHelper
  # How long ago something happened, in words. Dates have no time of day, and
  # time_ago_in_words reads one as midnight, so something done today would be
  # "19 hours ago"; a date is described by the day instead.
  def ago_in_words(value)
    return t('home.dashboard.relative.ago', time: time_ago_in_words(value)) if value.respond_to?(:hour)

    days = (Time.zone.today - value.to_date).to_i
    case days
    when ..0 then t('home.dashboard.relative.today')
    when 1 then t('home.dashboard.relative.yesterday')
    else t('home.dashboard.relative.ago', time: distance_of_time_in_words(value.to_date, Time.zone.today))
    end
  end

  # What the planting dialogs on the home page need to know about each planting
  # the member could pick: where to find it, when it was planted, whether it is
  # ready, and the crop's name.
  def planting_picker_props(dashboard)
    dashboard.harvest_choices.map do |planting|
      { id: planting.id, url: planting_path(slug: planting.slug), planted_at: planting.planted_at&.iso8601,
        ready: dashboard.ready.include?(planting), crop: { name: planting.crop_name } }
    end
  end

  # What the Growing now table needs: the first ten rows of what is growing and
  # of what is ready, already worded, so the chips can switch between them in
  # the browser.
  def growing_table_props(dashboard)
    {
      growing: growing_rows(dashboard.growing), ready: growing_rows(dashboard.ready),
      chips: { growing: t('home.dashboard.chip_growing', count: dashboard.growing.size),
               ready:   t('home.dashboard.chip_ready', count: dashboard.ready.size) },
      initial: params[:show] == 'ready' ? 'ready' : 'growing',
      labels: %i(col_plant col_bed col_planted col_maturity col_progress nothing_ready).index_with { |key| t("home.dashboard.#{key}") }
    }
  end

  # What the Harvest by month chart needs: the totals for each month, and the
  # wording for each way of measuring them.
  def harvest_chart_props(dashboard)
    {
      months: dashboard.harvest_by_month.map { |entry| entry.merge(label: month_name(entry[:month], abbreviated: true)) },
      current_month: Time.zone.today.month,
      measures: %i(harvests kilograms).zip(%i(count weight)).map do |measure, key|
        { key: measure, label: t("home.dashboard.harvest_by_month_#{key}"), note: t("home.dashboard.harvest_by_month_note_#{key}"),
          unit: t("home.dashboard.harvest_by_month_unit_#{key}") }
      end
    }
  end

  # "October", or "Oct" when abbreviated, for a month number.
  def month_name(month, abbreviated: false)
    I18n.l(Date.new(2000, month, 1), format: abbreviated ? '%b' : '%B')
  end

  def current_month_name
    month_name(Time.zone.today.month)
  end

  # A green-headed white box on the home page: a title, an optional link or
  # button on the right of the header, and whatever the block holds.
  def home_section(title, action: nil, &)
    content_tag(:section, class: 'home-section') do
      safe_join([
                  content_tag(:div, class: 'home-section-head') { safe_join([content_tag(:h2, title), action]) },
                  capture(&)
                ])
    end
  end

  private

  def growing_rows(plantings)
    plantings.first(10).map do |planting|
      days = planting.crop.median_days_to_first_harvest
      { id: planting.id, name: planting.crop_name, url: planting_path(slug: planting.slug), garden: planting.garden_name,
        image_url: planting.thumbnail_url || image_path(placeholder_image),
        planted: planting.planted_at&.strftime('%b %-d'),
        maturity: if planting.harvest_time? then t('home.dashboard.ready')
                  elsif days then t('home.dashboard.days', count: days)
                  else ''
                  end,
        progress: planting.harvest_time? ? 100 : planting.percentage_grown.to_i }
    end
  end
end

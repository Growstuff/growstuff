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
end

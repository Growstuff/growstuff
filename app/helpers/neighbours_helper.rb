# frozen_string_literal: true

module NeighboursHelper
  include SeasonsHelper
  include HarvestsHelper

  PICTURES_SHOWN = 8
  LAUNCHED_ON = Date.new(2026, 10, 14)
  NEW_FOR = 3.months
  NEW_AFTER_VISIT = 24.hours

  # The "New" badge and welcome banner show until the member has had a day
  # with the page, or three months after launch. Someone who has never opened
  # it still sees them after that.
  def neighbours_new?
    first_seen = current_member.feature_first_seen_at(:neighbours)
    return true unless first_seen

    Time.current < first_seen + NEW_AFTER_VISIT && Time.zone.today < LAUNCHED_ON + NEW_FOR
  end

  # "Today · Tue 13 Oct", "Yesterday · Mon 12 Oct", then just "Sun 11 Oct".
  def day_heading(day)
    date = l(day, format: '%a %-d %b')
    today = Time.zone.today
    return t('neighbours.day.today', date:) if day == today

    day == today - 1 ? t('neighbours.day.yesterday', date:) : date
  end

  GROUP_ORDER = %w(planting seed seed_trade harvest transplant planted_out planting_finished seed_finished activity garden_layout).freeze

  # The icon that goes with each kind of thing someone did.
  def group_icon(kind)
    case kind
    when 'planting' then planting_icon
    when 'seed', 'seed_trade' then seed_icon
    when 'harvest' then harvest_icon
    when 'transplant', 'planted_out' then growing_icon
    when 'planting_finished', 'seed_finished' then finished_icon
    when 'activity' then activity_icon
    when 'garden_layout' then garden_icon
    when 'photo' then photo_icon
    end
  end

  # What someone did in a day, as [kind, garden, items]: everything they
  # planted together, everything they harvested together, and so on. Moves are
  # grouped by where they went, and "planted out" when they came from the nursery.
  def entry_groups(entry)
    entry.others.group_by { |item| group_key(item) }
      .sort_by.with_index { |((kind, _garden), _items), index| [GROUP_ORDER.index(kind), index] }
      .map { |(kind, garden), items| [kind, garden, items] }
  end

  # "Harvested tomato and basil", "Planted out kale into The Deck".
  def group_sentence(kind, garden, items)
    things = sentence_of(items.map { |item| group_thing(item) })
    t("neighbours.group.#{kind}_html", things:, count: items.size, garden: (link_to(garden.name, polymorphic_path(garden)) if garden))
  end

  SEASON_STARTS = [3, 6, 9, 12].freeze

  # The first day of the season a date is in. Both hemispheres change season
  # on the same days, so this tells us where a marker goes whichever half of
  # the world someone gardens in.
  def season_start(date)
    month = SEASON_STARTS.select { |start| start <= date.month }.max
    month ? Date.new(date.year, month, 1) : Date.new(date.year - 1, 12, 1)
  end

  # "Spring 2026", or "Spring 2026 · Autumn in the northern hemisphere" when
  # the feed has people in both halves of the world. Their own hemisphere is
  # not named, unless they have not said where they live.
  def season_heading(start, neighbours)
    hemispheres = neighbours.hemispheres
    return if hemispheres.empty?

    mine = hemisphere(neighbours.member.latitude)
    names = hemispheres.map do |half|
      season = t("seasons.#{season_in(half, start)}")
      hemispheres.one? || half == mine ? season : t('neighbours.season.in_hemisphere', season:, hemisphere: t("neighbours.season.#{half}"))
    end
    "#{names.first} #{start.year}#{names.drop(1).map { |name| " · #{name}" }.join}"
  end

  # Where someone is and when they did it: "Upper Hutt · 2 hours ago", or
  # "from 7:40am" when they did several things in a day.
  def entry_when(entry)
    times = entry.items.filter_map(&:at)
    when_text = if times.empty? then nil
                elsif entry.items.one? && entry.day == Time.zone.today then ago_in_words(times.first)
                elsif entry.items.one? then times.first.strftime('%-l:%M%P')
                else t('neighbours.day.from', time: times.min.strftime('%-l:%M%P'))
                end
    [entry.owner.location.presence, when_text].compact.join(' · ')
  end

  # Where to get the chunk of the feed after the one on the page.
  def next_feed_path(neighbours)
    neighbours_feed_path(scope: neighbours.scope, offset: neighbours.next_offset, after: neighbours.feed.last.day.iso8601)
  end

  # Pictures for an entry, photos first, each linking to the thing it is of
  # (the planting, rather than the photo) when there is one.
  def entry_images(entry)
    photos = entry.photos.map { |item| { url: item.record.thumbnail_url, link: item.subject || item.record } }
    records = entry.others.map(&:record).select { |record| record.respond_to?(:thumbnail_url) }
    others = records.map { |record| { url: record.thumbnail_url, link: record } }
    (photos + others).uniq { |image| image[:url] }.select { |image| image[:url] }.first(PICTURES_SHOWN)
  end

  # "Photo of a tomato planting", "3 photos of a tomato planting": the item
  # rather than the photo is the interesting part, so that is what links.
  def photo_group_text(subject, count, alone)
    if alone
      link_to t('neighbours.photos.added', count:), polymorphic_path(subject)
    else
      t('neighbours.photos.of_html', count:, subject: link_to(subject_label(subject), polymorphic_path(subject)))
    end
  end

  def group_key(item)
    case item.type
    when 'seed' then [item.record.tradable ? 'seed_trade' : 'seed']
    when 'transplant' then [item.record.garden.nursery? ? 'planted_out' : 'transplant', item.record.moved_to]
    else [item.type]
    end
  end

  def group_thing(item)
    record = item.record
    case item.type
    when 'activity'
      link = link_to(record.name, polymorphic_path(record))
      record.due_date ? safe_join([link, " (#{t('neighbours.group.due', date: l(record.due_date, format: '%-d %b'))})"]) : link
    when 'garden_layout' then link_to(record.name, polymorphic_path(record))
    when 'transplant' then link_to(record.planting.crop.name, polymorphic_path(record.planting))
    when 'harvest' then with_details(link_to(record.crop.name, polymorphic_path(record)), harvest_details(record))
    else link_to(record.crop.name, polymorphic_path(record))
    end
  end

  def with_details(link, details)
    details ? safe_join([link, " (#{details})"]) : link
  end

  # What they said they picked: "2 kg", "3 buckets, weighing 4 kg", "×12".
  def harvest_details(harvest)
    count = display_human_quantity(harvest)
    count = "×#{count}" if count && harvest.unit == 'individual'
    weight = display_weight(harvest)
    return count unless weight
    return weight unless count

    "#{count}, #{t('neighbours.group.weighing', weight:)}"
  end

  def sentence_of(links)
    return links.first if links.one?
    return safe_join(links, t('support.array.two_words_connector')) if links.size == 2

    safe_join([safe_join(links.first(links.size - 1), t('support.array.words_connector')), links.last],
              t('support.array.last_word_connector'))
  end

  def season_in(hemisphere, start)
    SEASON_MONTHS.fetch(hemisphere).find { |_season, months| months.include?(start.month) }.first
  end

  def subject_label(subject)
    case subject
    when Garden then t('neighbours.subject.garden', name: subject.name)
    else t("neighbours.subject.#{subject.class.name.downcase}", crop: subject.crop.name)
    end
  end
end

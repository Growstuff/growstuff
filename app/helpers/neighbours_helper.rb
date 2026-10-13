# frozen_string_literal: true

module NeighboursHelper
  PICTURES_SHOWN = 8

  # "Today · Tue 13 Oct", "Yesterday · Mon 12 Oct", then just "Sun 11 Oct".
  def day_heading(day)
    date = l(day, format: '%a %-d %b')
    today = Time.zone.today
    return t('neighbours.day.today', date:) if day == today

    day == today - 1 ? t('neighbours.day.yesterday', date:) : date
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

  def subject_label(subject)
    case subject
    when Garden then t('neighbours.subject.garden', name: subject.name)
    else t("neighbours.subject.#{subject.class.name.downcase}", crop: subject.crop.name)
    end
  end
end

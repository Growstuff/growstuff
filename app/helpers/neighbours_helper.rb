# frozen_string_literal: true

module NeighboursHelper
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
    photos = entry.photos.map { |item| image_of(item.record.thumbnail_url, item.subject || item.record) }
    others = entry.others.map(&:record).map { |record| image_of(own_photo_url(record), record) }
    (photos + others).uniq { |image| image[:url] }.select { |image| image[:url] }.first(PICTURES_SHOWN)
  end

  # A picture and what it is of, as a caption: "A tomato planting".
  def image_of(url, link)
    label = subject_label(link).upcase_first unless link.is_a?(Photo)
    { url:, link:, label: }
  end

  # The record's own best photo, never the crop's stand-in that
  # thumbnail_url falls back to.
  def own_photo_url(record)
    photo = record.most_liked_photo if record.respond_to?(:most_liked_photo)
    return unless photo

    photo.source == 'flickr' ? photo.fullsize_url : photo.thumbnail_url
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

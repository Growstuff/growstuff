# frozen_string_literal: true

require 'nokogiri'
module ApplicationHelper
  def parse_date(str)
    str ||= '' # Date.parse barfs on nil
    str == '' ? nil : Date.parse(str)
  end

  def build_alert_classes(alert_type = :info)
    classes = 'alert alert-dismissable '
    case alert_type.to_sym
    when :alert, :danger, :error, :validation_errors
      classes += 'alert-danger'
    when :warning, :todo
      classes += 'alert-warning'
    when :notice, :success
      classes += 'alert-success'
    when :info
      classes += 'alert-info'
    end
    classes
  end

  # Similar to Rails' time_ago_in_words, but gives a more standard
  # output like "in 3 days" or "5 months ago".
  # Also handles the case where from_time is a Date and to_time is a Date
  # (in which case it just says "today" if they're the same date).
  #
  # NOTE: This is similar to distance_of_time_in_words but different enough
  # that I think it's worth having a separate helper for it.
  #
  # from_time - the starting time (Time or Date)
  # to_time - the ending time (Time or Date). Default: now (Time.zone.now)
  # include_seconds - whether to include seconds in the calculation
  #
  # Returns a string like "in 3 days" or "5 months ago"
  def standard_time_distance(from_time, to_time = 0, include_seconds = false)
    return 'today' if from_time.is_a?(Date) && (from_time == to_time)

    return 'now' if from_time == to_time
    return "#{distance_of_time_in_words(from_time, to_time, include_seconds:)} ago" if from_time < to_time

    "in #{distance_of_time_in_words(from_time, to_time, include_seconds:)}"
  end

  def count_github_contibutors
    File.open(Rails.root.join('CONTRIBUTORS.md')).readlines.grep(/^-/).size
  end

  # Produces a cache key for uniquely identifying cached fragments.
  def cache_key_for(klass, identifier = "all")
    count          = klass.count
    max_updated_at = klass.maximum(:updated_at).try(:utc).try(:to_fs, :number)
    "#{klass.name.downcase.pluralize}/#{identifier}-#{count}-#{max_updated_at}"
  end

  # A helper to replace the complex template compilation mess
  # of HAML, Tilt, and dynamic compilation with interpolated ruby.
  def markdownify(text)
    translator = Haml::Filters::GrowstuffMarkdown.new
    translator.expand_members!(translator.expand_crops!(text.to_s))
  end

  #
  # Returns an image uri for a given member.
  #
  # Falls back to Gravatar
  #
  def avatar_uri(member, size = 150)
    return unless member

    if member.preferred_avatar_uri.present?
      # Some avatars support different sizes
      # http://graph.facebook.com/12345678/picture?width=150&height=150
      uri = URI.parse(member.preferred_avatar_uri)

      uri.query = "&width=#{size}&height=#{size}" if uri.host == 'graph.facebook.com'

      # TODO: Assess flickr  - https://www.flickr.com/services/api/misc.buddyicons.html

      return uri.to_s
    end

    Gravatar.new(member.email).image_url(size:,
                                         default: :identicon,
                                         ssl:     true)
  end

  # Returns a string with the quantity and the right pluralization for a
  # given collection and model.
  def localize_plural(collection, model)
    pluralize(collection.size, model.model_name.to_s.downcase)
  end

  def show_inactive_tickbox_path(type, owner: nil, crop: nil, show_all: false)
    all = show_all ? '' : 1

    if owner.present?
      public_send("member_#{type}_path", owner, all:)
    elsif crop.present?
      public_send("crop_#{type}_path", crop, all:)
    else
      public_send("#{type}_path", all:)
    end
  end

  def title(type, owner, crop, planting)
    if owner
      t(".title.owner_#{type}", owner: owner.login_name)
    elsif crop
      t(".title.crop_#{type}", crop: crop.name)
    elsif planting
      t(".title.planting_#{type}", planting: planting.to_s)
    else
      t(".title.default")
    end
  end

  def og_description(description)
    strip_tags(description).split(' ')[0..20].join(' ')
  end

  def github_releases
    feed_url = 'https://github.com/Growstuff/growstuff/releases.atom'
    Rails.cache.fetch(feed_url, expires_in: 1.day) do
      response = Faraday.get(feed_url)
      doc = Nokogiri::XML(response.body)
      doc.xpath('//xmlns:entry').first(3).map do |entry|
        {
          title: entry.xpath('xmlns:title').text,
          link: entry.xpath('xmlns:link/@href').text
        }
      end
    end
  end
end

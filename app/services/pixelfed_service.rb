# frozen_string_literal: true

require 'faraday'
require 'json'

class PixelfedService
  class Error < StandardError; end

  ACTIVITY_PUB_HEADERS = {
    'Accept' => 'application/activity+json, application/ld+json; profile="https://www.w3.org/ns/activitystreams"',
    'User-Agent' => 'Growstuff/1.0'
  }.freeze

  def self.extract_metadata(input)
    new(input).extract_metadata
  end

  def initialize(input)
    @input = input
  end

  def extract_metadata
    payload = parse_input(@input)
    payload = payload['object'] if payload.is_a?(Hash) && payload['type'] == 'Create' && payload['object'].is_a?(Hash)

    raise Error, 'Invalid ActivityPub payload' unless payload.is_a?(Hash)

    source_id = payload['id']
    raise Error, 'ActivityPub object missing id' if source_id.blank?

    link_url = extract_link_url(payload) || source_id
    fullsize_url, thumbnail_url = extract_image_urls(payload)

    raise Error, 'No image found in ActivityPub object' if fullsize_url.blank?

    title = extract_title(payload)
    license_name, license_url = extract_license(payload)
    date_taken = extract_date(payload)

    {
      source: 'pixelfed',
      source_id: source_id,
      title: title,
      fullsize_url: fullsize_url,
      thumbnail_url: thumbnail_url || fullsize_url,
      link_url: link_url,
      license_name: license_name,
      license_url: license_url,
      date_taken: date_taken
    }.compact
  end

  private

  def parse_input(input)
    if input.is_a?(Hash)
      input
    elsif input.is_a?(String)
      trimmed = input.strip
      if trimmed.start_with?('{')
        JSON.parse(trimmed)
      elsif trimmed.match?(%r{\Ahttps?://})
        fetch_url(trimmed)
      else
        raise Error, 'Invalid input format'
      end
    else
      raise Error, 'Invalid input format'
    end
  rescue JSON::ParserError => e
    raise Error, "Failed to parse ActivityPub JSON: #{e.message}"
  end

  def fetch_url(url)
    response = Faraday.get(url, nil, ACTIVITY_PUB_HEADERS)
    raise Error, "HTTP request failed with status #{response.status}" unless response.success?

    JSON.parse(response.body)
  rescue Faraday::Error => e
    raise Error, "Failed to fetch ActivityPub object from #{url}: #{e.message}"
  end

  def extract_title(payload)
    raw_title = payload['name'] || payload['summary'] || payload['content']
    clean_title = ActionController::Base.helpers.strip_tags(raw_title.to_s).strip if raw_title.present?
    clean_title.presence || 'Pixelfed Photo'
  end

  def extract_link_url(payload)
    url = payload['url']
    if url.is_a?(Hash)
      url['href']
    elsif url.is_a?(Array)
      first = url.first
      first.is_a?(Hash) ? first['href'] : first.to_s
    elsif url.is_a?(String)
      url
    end
  end

  def extract_image_urls(payload)
    attachments = Array(payload['attachment'])
    image_attachment = attachments.find do |att|
      next false unless att.is_a?(Hash)

      type = att['type']
      media_type = att['mediaType'] || att['mimeType']
      type == 'Image' || (media_type && media_type.start_with?('image/'))
    end

    image_attachment ||= attachments.first if attachments.first.is_a?(Hash)

    fullsize = nil
    thumbnail = nil

    if image_attachment
      fullsize = extract_url_from_attachment(image_attachment)
      thumbnail = extract_thumbnail_from_attachment(image_attachment)
    elsif payload['type'] == 'Image'
      fullsize = extract_link_url(payload)
      thumbnail = payload.dig('icon', 'url') || payload.dig('preview', 'url')
    end

    [fullsize, thumbnail]
  end

  def extract_url_from_attachment(att)
    url = att['url'] || att['href']
    if url.is_a?(Hash)
      url['href'] || url['url']
    elsif url.is_a?(Array)
      first = url.first
      first.is_a?(Hash) ? (first['href'] || first['url']) : first.to_s
    elsif url.is_a?(String)
      url
    end
  end

  def extract_thumbnail_from_attachment(att)
    icon = att['icon'] || att['preview']
    if icon.is_a?(Hash)
      icon['url'] || icon['href']
    elsif icon.is_a?(String)
      icon
    end
  end

  def extract_license(payload)
    license = payload['license']
    license_url = nil
    license_name = nil

    if license.is_a?(String) && license.match?(%r{\Ahttps?://})
      license_url = license
      license_name = parse_license_name_from_url(license)
    elsif license.is_a?(String)
      license_name = license
    elsif license.is_a?(Hash)
      license_url = license['url'] || license['href']
      license_name = license['name'] || parse_license_name_from_url(license_url)
    end

    license_name ||= 'CC-BY'
    [license_name, license_url]
  end

  def parse_license_name_from_url(url)
    return nil if url.blank?

    if url.include?('creativecommons.org')
      parts = url.split('/')
      # e.g. https://creativecommons.org/licenses/by/4.0/
      if (idx = parts.index('licenses')) && parts[idx + 1]
        type = parts[idx + 1].upcase
        version = parts[idx + 2]
        "CC-#{type}#{version ? " #{version}" : ''}"
      else
        'CC-BY'
      end
    else
      'Custom License'
    end
  end

  def extract_date(payload)
    date_str = payload['published'] || payload['updated']
    Time.zone.parse(date_str) if date_str.present?
  rescue ArgumentError, TypeError
    nil
  end
end

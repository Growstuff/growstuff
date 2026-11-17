# frozen_string_literal: true

require 'ipaddr'
require 'resolv'

# Public photos on a linked account's home server. Only metadata is imported;
# image files stay on that server (or its CDN). No OAuth token is needed or kept.
class MastodonPhotoSource
  class Rejected < StandardError
    attr_reader :reason

    def initialize(reason)
      @reason = reason
      super(reason.to_s)
    end
  end

  LICENSE_NAME = 'CC BY-SA 4.0'
  LICENSE_URL = 'https://creativecommons.org/licenses/by-sa/4.0/'
  ID_FORMAT = /\A[0-9]+\z/
  # A page of 40 statuses is a few hundred KB; this is well beyond that, and still small.
  MAX_RESPONSE_BYTES = 2.megabytes
  # Each failed connection can take the full open timeout, so only try a few addresses.
  MAX_ADDRESSES = 3

  def initialize(authentication, resolver: Resolv, adapter: :net_http)
    @authentication = authentication
    @account_id, @domain = authentication.uid.to_s.split('@', 2)
    @resolver = resolver
    @adapter = Array(adapter)
    reject! unless authentication.provider == 'mastodon' && ID_FORMAT.match?(@account_id.to_s) &&
                   MastodonClientService::DOMAIN_FORMAT.match?(@domain.to_s)
  end

  def photos(cursor: nil, tag: nil)
    reject! if cursor.present? && !ID_FORMAT.match?(cursor.to_s)
    query = { only_media: true, exclude_reblogs: true, limit: 40 }
    query[:max_id] = cursor if cursor.present?
    query[:tagged] = tag if tag.present?
    statuses = request("/api/v1/accounts/#{@account_id}/statuses", query)
    reject!(:unavailable) unless statuses.is_a?(Array) && statuses.all?(Hash)

    candidates = statuses.select { |status| eligible?(status) }.flat_map do |status|
      Array(status['media_attachments']).filter_map { |attachment| [status, attachment] if image?(attachment) }
    end
    known = Photo.where(owner: @authentication.member, source: 'mastodon',
                        source_id: candidates.map { |_status, attachment| source_id(attachment) }).index_by(&:source_id)
    {
      photos:      candidates.map do |status, attachment|
        picker_photo(status, attachment, known[source_id(attachment)])
      end,
      # The cursor is the last *status*, even if every attachment was filtered out.
      next_cursor: statuses.last&.fetch('id', nil)
    }
  end

  def import(status_id:, attachment_id:, license_accepted:)
    reject! unless [status_id, attachment_id].all? { |id| ID_FORMAT.match?(id.to_s) }
    status = request("/api/v1/statuses/#{status_id}")
    reject! unless status.is_a?(Hash) && status['id'] == status_id.to_s && eligible?(status)
    attachment = Array(status['media_attachments']).find { |media| media.is_a?(Hash) && media['id'] == attachment_id.to_s }
    reject! unless image?(attachment)

    photo = existing_photo(attachment) || Photo.new(source: 'mastodon', source_id: source_id(attachment), owner: @authentication.member)
    reject!(:license_required) if photo.license_name.blank? && !ActiveModel::Type::Boolean.new.cast(license_accepted)
    photo.assign_attributes(
      thumbnail_url: attachment['preview_url'].presence || attachment['url'],
      fullsize_url: attachment['url'], link_url: status['url'],
      title: photo.title.presence || attachment['description'].presence || I18n.t('photos.import_picker.untitled'),
      license_name: photo.license_name.presence || LICENSE_NAME,
      license_url: photo.license_name.present? ? photo.license_url : LICENSE_URL
    )
    photo
  end

  private

  def source_id(attachment)
    "#{attachment['id']}@#{@domain}"
  end

  def existing_photo(attachment)
    Photo.find_by(source: 'mastodon', source_id: source_id(attachment), owner: @authentication.member)
  end

  def picker_photo(status, attachment, photo)
    { id: attachment['id'], status_id: status['id'],
      title: attachment['description'].presence || I18n.t('photos.import_picker.untitled'),
      thumb_url: attachment['preview_url'].presence || attachment['url'], preview_url: attachment['url'],
      license_name: photo&.license_name, license_url: photo&.license_url }
  end

  def eligible?(status)
    ID_FORMAT.match?(status['id'].to_s) && status['account'].is_a?(Hash) &&
      status['account']['id'] == @account_id && status['visibility'] == 'public' &&
      status['reblog'].nil? && status['sensitive'] != true && status['spoiler_text'].blank? && https_url?(status['url'])
  end

  def image?(attachment)
    attachment.is_a?(Hash) && attachment['type'] == 'image' && ID_FORMAT.match?(attachment['id'].to_s) &&
      https_url?(attachment['url']) && (attachment['preview_url'].blank? || https_url?(attachment['preview_url']))
  end

  def https_url?(value)
    uri = URI.parse(value.to_s)
    uri.is_a?(URI::HTTPS) && uri.host.present? && uri.userinfo.nil?
  rescue URI::InvalidURIError
    false
  end

  def request(path, query = {})
    addresses = @resolver.getaddresses(@domain).map { |address| IPAddr.new(address) }
    reject!(:unavailable) if addresses.empty? || addresses.any? { |address| blocked?(address) }
    JSON.parse(fetch_from_any(addresses.first(MAX_ADDRESSES), path, query))
  rescue Faraday::Error, JSON::ParserError, Resolv::ResolvError, IPAddr::Error, SocketError
    reject!(:unavailable)
  end

  # A server can have addresses we can't reach (an IPv6 one with no route from here, say),
  # so try each in turn, and only give up when the last one fails to connect too.
  def fetch_from_any(addresses, path, query)
    addresses.each_with_index do |address, index|
      return fetch(address, path, query)
    rescue Faraday::ConnectionFailed
      raise if index == addresses.size - 1
    end
  end

  def fetch(address, path, query)
    streamed = +''
    response = connection(address).get(path, query) do |request|
      # Give up as soon as the body is too big, instead of holding all of it in memory first.
      request.options.on_data = proc { |chunk, _received, _env| stop_if_too_big(streamed << chunk) } if @adapter.first == :net_http
    end
    reject!(:unavailable) unless response.success?
    # Other adapters (the test one) don't stream: they hand over the whole body.
    stop_if_too_big(streamed.presence || response.body.to_s)
  end

  def stop_if_too_big(body)
    reject!(:unavailable) if body.bytesize > MAX_RESPONSE_BYTES
    body
  end

  # Pin the checked address, retaining the hostname for TLS verification. Do not
  # follow redirects or send credentials to a URL supplied by a remote server.
  def connection(address)
    Faraday.new(url: "https://#{@domain}", proxy: nil) do |faraday|
      faraday.options.open_timeout = 5
      faraday.options.timeout = 10
      if @adapter.first == :net_http
        faraday.adapter(*@adapter) { |http| http.ipaddr = address.to_s }
      else
        faraday.adapter(*@adapter)
      end
    end
  end

  def blocked?(address)
    address = address.native if address.ipv4_mapped?
    MastodonClientService::BLOCKED_RANGES.any? { |range| range.family == address.family && range.include?(address) }
  end

  def reject!(reason = :invalid_photo)
    raise Rejected, reason
  end
end
